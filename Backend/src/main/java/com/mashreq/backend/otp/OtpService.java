package com.mashreq.backend.otp;

import com.mashreq.backend.api.ApiException;
import com.mashreq.backend.config.AppProperties;
import com.mashreq.backend.delivery.DeliveryService;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class OtpService {
    private static final ZoneId GST = ZoneId.of("Asia/Dubai");
    private static final DateTimeFormatter REQUEST_TIME =
            DateTimeFormatter.ofPattern("dd MMM uuuu 'at' hh:mm a 'GST'", Locale.ENGLISH);

    private final JdbcTemplate jdbc;
    private final TransactionTemplate transactions;
    private final DeliveryService deliveryService;
    private final SecureRandom secureRandom;
    private final Clock clock;
    private final AppProperties properties;

    public OtpService(
            JdbcTemplate jdbc,
            TransactionTemplate transactions,
            DeliveryService deliveryService,
            SecureRandom secureRandom,
            Clock clock,
            AppProperties properties
    ) {
        this.jdbc = jdbc;
        this.transactions = transactions;
        this.deliveryService = deliveryService;
        this.secureRandom = secureRandom;
        this.clock = clock;
        this.properties = properties;
        if (properties.otp().pepper() == null || properties.otp().pepper().length() < 32) {
            throw new IllegalStateException("OTP_PEPPER must contain at least 32 characters");
        }
        if (properties.delivery().isLive() && properties.otp().pepper().startsWith("development-only")) {
            throw new IllegalStateException("A unique OTP_PEPPER is required in live delivery mode");
        }
    }

    public ChallengeResponse send(UUID customerId, Purpose purpose, List<Channel> channels) {
        if (channels.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "CHANNEL_REQUIRED", "At least one delivery channel is required");
        }
        int recent = jdbc.queryForObject("""
                SELECT count(*)
                FROM otp_challenges
                WHERE customer_id = ?
                  AND purpose = ?
                  AND created_at > ?
                """, Integer.class, customerId, purpose.name(),
                Timestamp.from(clock.instant().minus(properties.otp().resendCooldown())));
        if (recent > 0) {
            throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "OTP_COOLDOWN", "Please wait before requesting another code");
        }

        CustomerContacts contacts = jdbc.queryForObject("""
                SELECT email, mobile_number
                FROM customers
                WHERE id = ?
                """, (rs, rowNum) -> new CustomerContacts(
                rs.getString("email"),
                rs.getString("mobile_number")
        ), customerId);

        UUID challengeId = UUID.randomUUID();
        String code = String.format(Locale.ROOT, "%06d", secureRandom.nextInt(1_000_000));
        Instant createdAt = clock.instant();
        Instant expiresAt = createdAt.plus(properties.otp().ttl());
        String joinedChannels = channels.stream().distinct().map(Enum::name).sorted().reduce((a, b) -> a + "," + b).orElseThrow();

        // Открытый OTP используется только для доставки; в PostgreSQL хранится HMAC-digest.
        jdbc.update("""
                INSERT INTO otp_challenges (
                    id, customer_id, purpose, channels, code_digest,
                    max_attempts, expires_at, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, challengeId, customerId, purpose.name(), joinedChannels,
                digest(challengeId, code), properties.otp().maxAttempts(),
                Timestamp.from(expiresAt), Timestamp.from(createdAt));

        String body = otpMessage(code, createdAt);
        List<DeliveryService.DeliveryResult> deliveries = new ArrayList<>();
        for (Channel channel : channels.stream().distinct().toList()) {
            if (channel == Channel.EMAIL) {
                deliveries.add(deliveryService.sendOtpEmail(customerId, contacts.email(), body));
            } else {
                deliveries.add(deliveryService.sendSms(customerId, contacts.mobileNumber(), "OTP", compactSms(code)));
            }
        }

        if (deliveries.stream().noneMatch(DeliveryService.DeliveryResult::accepted)) {
            jdbc.update("UPDATE otp_challenges SET consumed_at = now() WHERE id = ?", challengeId);
            throw new ApiException(HttpStatus.BAD_GATEWAY, "OTP_DELIVERY_FAILED", "The OTP could not be delivered");
        }

        String debugCode = !properties.delivery().isLive() && properties.delivery().allowDebugOtp() ? code : null;
        return new ChallengeResponse(challengeId, purpose, expiresAt, deliveries, debugCode);
    }

    public VerificationResponse verify(UUID customerId, UUID challengeId, String code) {
        // FOR UPDATE делает проверку и одноразовое погашение кода атомарными.
        VerificationOutcome outcome = transactions.execute(status -> {
            Challenge challenge = jdbc.query("""
                    SELECT code_digest, attempts, max_attempts, expires_at, consumed_at
                    FROM otp_challenges
                    WHERE id = ? AND customer_id = ?
                    FOR UPDATE
                    """, rs -> rs.next() ? new Challenge(
                    rs.getBytes("code_digest"),
                    rs.getInt("attempts"),
                    rs.getInt("max_attempts"),
                    rs.getTimestamp("expires_at").toInstant(),
                    rs.getTimestamp("consumed_at") == null ? null : rs.getTimestamp("consumed_at").toInstant()
            ) : null, challengeId, customerId);

            if (challenge == null) {
                return VerificationOutcome.NOT_FOUND;
            }
            if (challenge.consumedAt() != null) {
                return VerificationOutcome.CONSUMED;
            }
            if (!challenge.expiresAt().isAfter(clock.instant())) {
                return VerificationOutcome.EXPIRED;
            }
            if (challenge.attempts() >= challenge.maxAttempts()) {
                return VerificationOutcome.LOCKED;
            }
            if (!MessageDigest.isEqual(challenge.codeDigest(), digest(challengeId, code))) {
                int attempts = challenge.attempts() + 1;
                jdbc.update("UPDATE otp_challenges SET attempts = ? WHERE id = ?", attempts, challengeId);
                return attempts >= challenge.maxAttempts() ? VerificationOutcome.LOCKED : VerificationOutcome.INVALID;
            }
            jdbc.update("UPDATE otp_challenges SET consumed_at = now() WHERE id = ?", challengeId);
            return VerificationOutcome.VERIFIED;
        });

        if (outcome == null) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "OTP_ERROR", "The OTP could not be verified");
        }
        return switch (outcome) {
            case VERIFIED -> new VerificationResponse(true, "VERIFIED");
            case NOT_FOUND -> throw new ApiException(HttpStatus.NOT_FOUND, "OTP_NOT_FOUND", "OTP challenge was not found");
            case CONSUMED -> throw new ApiException(HttpStatus.CONFLICT, "OTP_ALREADY_USED", "OTP has already been used");
            case EXPIRED -> throw new ApiException(HttpStatus.GONE, "OTP_EXPIRED", "OTP has expired");
            case LOCKED -> throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "OTP_LOCKED", "Too many incorrect attempts");
            case INVALID -> throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "OTP_INVALID", "OTP is incorrect");
        };
    }

    private byte[] digest(UUID challengeId, String code) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(properties.otp().pepper().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return mac.doFinal((challengeId + ":" + code).getBytes(StandardCharsets.UTF_8));
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to calculate OTP digest", exception);
        }
    }

    private static String otpMessage(String code, Instant requestedAt) {
        return """
                Dear Customer,

                %s is your one time password. Please use this password within the next 5 minutes to start your Mashreq Business Banking journey, requested on %s.

                Regards,
                Mashreq Team
                """.formatted(code, REQUEST_TIME.format(requestedAt.atZone(GST)));
    }

    private static String compactSms(String code) {
        return "Mashreq OTP: " + code + ". Valid for 5 minutes. Do not share this code.";
    }

    public enum Purpose {
        REGISTRATION,
        LOGIN,
        BENEFICIARY_ADDED,
        TRANSFER,
        DEBIT,
        CREDIT
    }

    public enum Channel {
        EMAIL,
        SMS
    }

    public record ChallengeResponse(
            UUID challengeId,
            Purpose purpose,
            Instant expiresAt,
            List<DeliveryService.DeliveryResult> deliveries,
            String debugCode
    ) {}

    public record VerificationResponse(boolean verified, String status) {}

    private record CustomerContacts(String email, String mobileNumber) {}

    private record Challenge(
            byte[] codeDigest,
            int attempts,
            int maxAttempts,
            Instant expiresAt,
            Instant consumedAt
    ) {}

    private enum VerificationOutcome {
        VERIFIED,
        NOT_FOUND,
        CONSUMED,
        EXPIRED,
        LOCKED,
        INVALID
    }
}
