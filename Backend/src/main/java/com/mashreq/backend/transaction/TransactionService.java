package com.mashreq.backend.transaction;

import com.mashreq.backend.api.ApiException;
import com.mashreq.backend.delivery.BankingNotificationService;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class TransactionService {
    private static final DateTimeFormatter REFERENCE_TIME =
            DateTimeFormatter.ofPattern("yyyyMMddHHmmss").withZone(ZoneOffset.UTC);

    private final JdbcTemplate jdbc;
    private final SecureRandom secureRandom;
    private final Clock clock;
    private final BankingNotificationService notificationService;

    public TransactionService(
            JdbcTemplate jdbc,
            SecureRandom secureRandom,
            Clock clock,
            BankingNotificationService notificationService
    ) {
        this.jdbc = jdbc;
        this.secureRandom = secureRandom;
        this.clock = clock;
        this.notificationService = notificationService;
    }

    public TransactionRecord create(UUID customerId, CreateTransaction command) {
        TransactionRecord existing = findByClientRequest(customerId, command.clientRequestId());
        if (existing != null) {
            return existing;
        }
        UUID id = UUID.randomUUID();
        Instant completedAt = clock.instant();
        String reference = "MLC" + REFERENCE_TIME.format(completedAt)
                + String.format(Locale.ROOT, "%04d", secureRandom.nextInt(10_000));

        int inserted = jdbc.update("""
                INSERT INTO banking_transactions (
                    id, customer_id, client_request_id, reference, transaction_type,
                    beneficiary_name, beneficiary_bank, beneficiary_country,
                    beneficiary_swift, beneficiary_iban, sender_account,
                    currency, amount, fee, purpose, status, completed_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT (customer_id, client_request_id) DO NOTHING
                """,
                id,
                customerId,
                command.clientRequestId(),
                reference,
                command.transactionType().name(),
                command.beneficiaryName().trim(),
                trimToNull(command.beneficiaryBank()),
                trimToNull(command.beneficiaryCountry()),
                trimToNull(command.beneficiarySwift()),
                normalizeIban(command.beneficiaryIban()),
                command.senderAccount().trim(),
                command.currency().toUpperCase(Locale.ROOT),
                command.amount(),
                command.fee(),
                trimToNull(command.purpose()),
                Status.COMPLETED.name(),
                Timestamp.from(completedAt)
        );

        if (inserted == 0) {
            return findByClientRequest(customerId, command.clientRequestId());
        }

        TransactionRecord transaction = findOwned(customerId, id);
        notificationService.transactionCompleted(customerId, transaction);
        return transaction;
    }

    private TransactionRecord findByClientRequest(UUID customerId, UUID clientRequestId) {
        List<TransactionRecord> rows = jdbc.query("""
                SELECT *
                FROM banking_transactions
                WHERE customer_id = ? AND client_request_id = ?
                """, (rs, rowNum) -> map(rs), customerId, clientRequestId);
        return rows.isEmpty() ? null : rows.getFirst();
    }

    public List<TransactionRecord> list(UUID customerId, int limit) {
        return jdbc.query("""
                SELECT *
                FROM banking_transactions
                WHERE customer_id = ?
                ORDER BY completed_at DESC
                LIMIT ?
                """, (rs, rowNum) -> map(rs), customerId, Math.min(Math.max(limit, 1), 100));
    }

    public TransactionRecord findOwned(UUID customerId, UUID transactionId) {
        try {
            return jdbc.queryForObject("""
                    SELECT *
                    FROM banking_transactions
                    WHERE id = ? AND customer_id = ?
                    """, (rs, rowNum) -> map(rs), transactionId, customerId);
        } catch (EmptyResultDataAccessException exception) {
            throw new ApiException(HttpStatus.NOT_FOUND, "TRANSACTION_NOT_FOUND", "Transaction was not found");
        }
    }

    private static TransactionRecord map(java.sql.ResultSet rs) throws java.sql.SQLException {
        return new TransactionRecord(
                rs.getObject("id", UUID.class),
                rs.getObject("customer_id", UUID.class),
                rs.getString("reference"),
                Type.valueOf(rs.getString("transaction_type")),
                rs.getString("beneficiary_name"),
                rs.getString("beneficiary_bank"),
                rs.getString("beneficiary_country"),
                rs.getString("beneficiary_swift"),
                rs.getString("beneficiary_iban"),
                rs.getString("sender_account"),
                rs.getString("currency"),
                rs.getBigDecimal("amount"),
                rs.getBigDecimal("fee"),
                rs.getString("purpose"),
                Status.valueOf(rs.getString("status")),
                rs.getTimestamp("completed_at").toInstant()
        );
    }

    private static String normalizeIban(String value) {
        return value == null ? null : value.replace(" ", "").trim().toUpperCase(Locale.ROOT);
    }

    private static String trimToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    public enum Type {
        LOCAL_TRANSFER,
        INTERNATIONAL_TRANSFER,
        ACCOUNT_CREDIT,
        ACCOUNT_DEBIT
    }

    public enum Status {
        COMPLETED,
        FAILED,
        PENDING
    }

    public record CreateTransaction(
            UUID clientRequestId,
            Type transactionType,
            String beneficiaryName,
            String beneficiaryBank,
            String beneficiaryCountry,
            String beneficiarySwift,
            String beneficiaryIban,
            String senderAccount,
            String currency,
            BigDecimal amount,
            BigDecimal fee,
            String purpose
    ) {}

    public record TransactionRecord(
            UUID id,
            UUID customerId,
            String reference,
            Type transactionType,
            String beneficiaryName,
            String beneficiaryBank,
            String beneficiaryCountry,
            String beneficiarySwift,
            String beneficiaryIban,
            String senderAccount,
            String currency,
            BigDecimal amount,
            BigDecimal fee,
            String purpose,
            Status status,
            Instant completedAt
    ) {}
}
