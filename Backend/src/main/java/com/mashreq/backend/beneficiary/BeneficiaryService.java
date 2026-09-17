package com.mashreq.backend.beneficiary;

import com.mashreq.backend.delivery.BankingNotificationService;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class BeneficiaryService {
    private final JdbcTemplate jdbc;
    private final BankingNotificationService notificationService;

    public BeneficiaryService(JdbcTemplate jdbc, BankingNotificationService notificationService) {
        this.jdbc = jdbc;
        this.notificationService = notificationService;
    }

    public Beneficiary create(UUID customerId, CreateBeneficiary command) {
        UUID id = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO beneficiaries (
                    id, customer_id, nickname, full_name,
                    bank_name, country, swift_code, iban
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, id, customerId, command.nickname().trim(), command.fullName().trim(),
                command.bankName().trim(), command.country().trim(), trimToNull(command.swiftCode()),
                command.iban().replace(" ", "").toUpperCase(Locale.ROOT));
        Beneficiary beneficiary = get(customerId, id);
        notificationService.beneficiaryAdded(customerId, beneficiary.fullName());
        return beneficiary;
    }

    public List<Beneficiary> list(UUID customerId) {
        return jdbc.query("""
                SELECT id, nickname, full_name, bank_name, country, swift_code, iban, created_at
                FROM beneficiaries
                WHERE customer_id = ?
                ORDER BY created_at DESC
                """, (rs, rowNum) -> map(rs), customerId);
    }

    private Beneficiary get(UUID customerId, UUID id) {
        return jdbc.queryForObject("""
                SELECT id, nickname, full_name, bank_name, country, swift_code, iban, created_at
                FROM beneficiaries
                WHERE id = ? AND customer_id = ?
                """, (rs, rowNum) -> map(rs), id, customerId);
    }

    private static Beneficiary map(java.sql.ResultSet rs) throws java.sql.SQLException {
        return new Beneficiary(
                rs.getObject("id", UUID.class),
                rs.getString("nickname"),
                rs.getString("full_name"),
                rs.getString("bank_name"),
                rs.getString("country"),
                rs.getString("swift_code"),
                rs.getString("iban"),
                rs.getTimestamp("created_at").toInstant()
        );
    }

    private static String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public record CreateBeneficiary(
            String nickname,
            String fullName,
            String bankName,
            String country,
            String swiftCode,
            String iban
    ) {}

    public record Beneficiary(
            UUID id,
            String nickname,
            String fullName,
            String bankName,
            String country,
            String swiftCode,
            String iban,
            Instant createdAt
    ) {}
}
