package com.mashreq.backend.delivery;

import com.mashreq.backend.config.AppProperties;
import com.twilio.Twilio;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import jakarta.mail.internet.MimeMessage;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

@Service
public class DeliveryService {
    private final JavaMailSender mailSender;
    private final JdbcTemplate jdbc;
    private final AppProperties properties;

    public DeliveryService(JavaMailSender mailSender, JdbcTemplate jdbc, AppProperties properties) {
        this.mailSender = mailSender;
        this.jdbc = jdbc;
        this.properties = properties;
    }

    public DeliveryResult sendOtpEmail(UUID customerId, String email, String body) {
        // В console-режиме внешней отправки нет, но результат фиксируется в журнале доставок.
        if (!properties.delivery().isLive()) {
            return record(customerId, "EMAIL", "OTP", maskEmail(email), "SKIPPED_CONSOLE", null, null);
        }
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, StandardCharsets.UTF_8.name());
            helper.setFrom(properties.delivery().smtpFrom());
            helper.setTo(email);
            helper.setSubject("Your Mashreq one time password");
            helper.setText(body, false);
            mailSender.send(message);
            return record(customerId, "EMAIL", "OTP", maskEmail(email), "SENT", null, null);
        } catch (Exception exception) {
            return record(customerId, "EMAIL", "OTP", maskEmail(email), "FAILED", null, exception.getClass().getSimpleName());
        }
    }

    public DeliveryResult sendSms(UUID customerId, String mobileNumber, String kind, String body) {
        if (!properties.delivery().isLive()) {
            return record(customerId, "SMS", kind, maskPhone(mobileNumber), "SKIPPED_CONSOLE", null, null);
        }
        AppProperties.Twilio twilio = properties.twilio();
        if (!StringUtils.hasText(twilio.accountSid()) || !StringUtils.hasText(twilio.authToken())) {
            return record(customerId, "SMS", kind, maskPhone(mobileNumber), "FAILED", null, "TWILIO_NOT_CONFIGURED");
        }
        try {
            Twilio.init(twilio.accountSid(), twilio.authToken());
            Message message;
            if (StringUtils.hasText(twilio.messagingServiceSid())) {
                message = Message.creator(new PhoneNumber(mobileNumber), twilio.messagingServiceSid(), body).create();
            } else {
                message = Message.creator(new PhoneNumber(mobileNumber), new PhoneNumber(twilio.fromNumber()), body).create();
            }
            return record(customerId, "SMS", kind, maskPhone(mobileNumber), "SENT", message.getSid(), null);
        } catch (Exception exception) {
            return record(customerId, "SMS", kind, maskPhone(mobileNumber), "FAILED", null, exception.getClass().getSimpleName());
        }
    }

    public DeliveryResult sendReceiptEmail(
            UUID customerId,
            String email,
            String fileName,
            byte[] pdf,
            String reference
    ) {
        if (!properties.delivery().isLive()) {
            return record(customerId, "EMAIL", "RECEIPT", maskEmail(email), "SKIPPED_CONSOLE", null, null);
        }
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());
            helper.setFrom(properties.delivery().smtpFrom());
            helper.setTo(email);
            helper.setSubject("Mashreq transfer receipt " + reference);
            helper.setText("Dear Customer,\n\nYour transfer receipt is attached.\n\nRegards,\nMashreq Team", false);
            helper.addAttachment(fileName, new ByteArrayResource(pdf), "application/pdf");
            mailSender.send(message);
            return record(customerId, "EMAIL", "RECEIPT", maskEmail(email), "SENT", null, null);
        } catch (Exception exception) {
            return record(customerId, "EMAIL", "RECEIPT", maskEmail(email), "FAILED", null, exception.getClass().getSimpleName());
        }
    }

    public DeliveryResult sendNotificationEmail(
            UUID customerId,
            String email,
            String kind,
            String subject,
            String body
    ) {
        if (!properties.delivery().isLive()) {
            return record(customerId, "EMAIL", kind, maskEmail(email), "SKIPPED_CONSOLE", null, null);
        }
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, StandardCharsets.UTF_8.name());
            helper.setFrom(properties.delivery().smtpFrom());
            helper.setTo(email);
            helper.setSubject(subject);
            helper.setText(body, false);
            mailSender.send(message);
            return record(customerId, "EMAIL", kind, maskEmail(email), "SENT", null, null);
        } catch (Exception exception) {
            return record(customerId, "EMAIL", kind, maskEmail(email), "FAILED", null, exception.getClass().getSimpleName());
        }
    }

    private DeliveryResult record(
            UUID customerId,
            String channel,
            String kind,
            String destinationMasked,
            String status,
            String providerMessageId,
            String errorCode
    ) {
        UUID id = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO message_deliveries (
                    id, customer_id, channel, kind, destination_masked,
                    provider_message_id, status, error_code
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, id, customerId, channel, kind, destinationMasked, providerMessageId, status, errorCode);
        return new DeliveryResult(id, channel, status, providerMessageId, errorCode);
    }

    private static String maskEmail(String email) {
        int at = email.indexOf('@');
        if (at <= 1) {
            return "***";
        }
        return email.substring(0, 1) + "***" + email.substring(at);
    }

    private static String maskPhone(String phone) {
        if (phone.length() <= 4) {
            return "****";
        }
        return "*".repeat(phone.length() - 4) + phone.substring(phone.length() - 4);
    }

    public record DeliveryResult(
            UUID id,
            String channel,
            String status,
            String providerMessageId,
            String errorCode
    ) {
        public boolean accepted() {
            return "SENT".equals(status) || "SKIPPED_CONSOLE".equals(status);
        }
    }
}
