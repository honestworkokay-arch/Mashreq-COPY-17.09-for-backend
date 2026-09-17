package com.mashreq.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@ConfigurationProperties(prefix = "app")
public record AppProperties(
        Auth auth,
        Otp otp,
        Delivery delivery,
        Twilio twilio
) {
    public record Auth(Duration sessionTtl) {}

    public record Otp(
            Duration ttl,
            Duration resendCooldown,
            int maxAttempts,
            String pepper
    ) {}

    public record Delivery(
            String mode,
            boolean allowDebugOtp,
            String smtpFrom
    ) {
        public boolean isLive() {
            return "live".equalsIgnoreCase(mode);
        }
    }

    public record Twilio(
            String accountSid,
            String authToken,
            String fromNumber,
            String messagingServiceSid
    ) {}
}
