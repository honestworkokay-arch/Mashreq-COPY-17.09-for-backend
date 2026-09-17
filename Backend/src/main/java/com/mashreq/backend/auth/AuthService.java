package com.mashreq.backend.auth;

import com.mashreq.backend.api.ApiException;
import com.mashreq.backend.config.AppProperties;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.Locale;
import java.util.UUID;

@Service
public class AuthService {
    private final JdbcTemplate jdbc;
    private final BCryptPasswordEncoder passwordEncoder;
    private final SecureRandom secureRandom;
    private final Clock clock;
    private final AppProperties properties;

    public AuthService(
            JdbcTemplate jdbc,
            BCryptPasswordEncoder passwordEncoder,
            SecureRandom secureRandom,
            Clock clock,
            AppProperties properties
    ) {
        this.jdbc = jdbc;
        this.passwordEncoder = passwordEncoder;
        this.secureRandom = secureRandom;
        this.clock = clock;
        this.properties = properties;
    }

    @Transactional
    public AuthResult register(RegistrationData data) {
        // Пароль никогда не сохраняется напрямую: в базу попадает только BCrypt-хэш.
        UUID customerId = UUID.randomUUID();
        String email = normalizeEmail(data.email());
        String iban = data.iban().replace(" ", "").toUpperCase(Locale.ROOT);

        jdbc.update("""
                INSERT INTO customers (
                    id, first_name, last_name, email, mobile_number,
                    iban, account_number, password_hash
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                customerId,
                data.firstName().trim(),
                data.lastName().trim(),
                email,
                data.mobileNumber().trim(),
                iban,
                data.accountNumber().trim(),
                passwordEncoder.encode(data.password())
        );

        return createSession(customerId, data.firstName().trim(), data.lastName().trim(), email);
    }

    public AuthResult login(String rawEmail, String password) {
        String email = normalizeEmail(rawEmail);
        CustomerCredentials customer;
        try {
            customer = jdbc.queryForObject("""
                    SELECT id, first_name, last_name, email, password_hash
                    FROM customers
                    WHERE lower(email) = ?
                    """, (rs, rowNum) -> new CustomerCredentials(
                    rs.getObject("id", UUID.class),
                    rs.getString("first_name"),
                    rs.getString("last_name"),
                    rs.getString("email"),
                    rs.getString("password_hash")
            ), email);
        } catch (EmptyResultDataAccessException exception) {
            throw invalidCredentials();
        }

        if (!passwordEncoder.matches(password, customer.passwordHash())) {
            throw invalidCredentials();
        }
        return createSession(customer.id(), customer.firstName(), customer.lastName(), customer.email());
    }

    public UUID authenticate(String rawToken) {
        byte[] tokenHash = sha256(rawToken);
        try {
            return jdbc.queryForObject("""
                    SELECT customer_id
                    FROM auth_sessions
                    WHERE token_hash = ?
                      AND revoked_at IS NULL
                      AND expires_at > now()
                    """, (rs, rowNum) -> rs.getObject("customer_id", UUID.class), tokenHash);
        } catch (EmptyResultDataAccessException exception) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "INVALID_TOKEN", "The bearer token is invalid or expired");
        }
    }

    public void revoke(String rawToken) {
        jdbc.update("UPDATE auth_sessions SET revoked_at = now() WHERE token_hash = ?", sha256(rawToken));
    }

    private AuthResult createSession(UUID customerId, String firstName, String lastName, String email) {
        // Клиент получает случайный token, сервер хранит только его SHA-256 отпечаток.
        byte[] tokenBytes = new byte[32];
        secureRandom.nextBytes(tokenBytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
        Instant expiresAt = clock.instant().plus(properties.auth().sessionTtl());

        jdbc.update("""
                INSERT INTO auth_sessions (customer_id, token_hash, expires_at)
                VALUES (?, ?, ?)
                """, customerId, sha256(token), Timestamp.from(expiresAt));

        return new AuthResult(token, expiresAt, new CustomerSummary(customerId, firstName, lastName, email));
    }

    private static String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private static byte[] sha256(String value) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private static ApiException invalidCredentials() {
        return new ApiException(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS", "Email or password is incorrect");
    }

    public record RegistrationData(
            String firstName,
            String lastName,
            String mobileNumber,
            String email,
            String iban,
            String accountNumber,
            String password
    ) {}

    public record AuthResult(String token, Instant expiresAt, CustomerSummary customer) {}

    public record CustomerSummary(UUID id, String firstName, String lastName, String email) {}

    private record CustomerCredentials(
            UUID id,
            String firstName,
            String lastName,
            String email,
            String passwordHash
    ) {}
}
