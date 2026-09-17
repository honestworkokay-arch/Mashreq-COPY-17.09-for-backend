package com.mashreq.backend.receipt;

import com.mashreq.backend.api.ApiException;
import com.mashreq.backend.delivery.DeliveryService;
import com.mashreq.backend.transaction.TransactionService;
import net.sf.jasperreports.engine.JREmptyDataSource;
import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JasperExportManager;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperReport;
import org.springframework.core.io.ClassPathResource;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Timestamp;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Service
public class ReceiptService {
    private static final String TEMPLATE_VERSION = "fund-transfer-v1";
    private static final ZoneId GST = ZoneId.of("Asia/Dubai");
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("dd MMM uuuu", Locale.ENGLISH);
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("hh:mm a 'GST'", Locale.ENGLISH);

    private final JdbcTemplate jdbc;
    private final TransactionService transactionService;
    private final DeliveryService deliveryService;
    private final Clock clock;
    private final JasperReport report;

    public ReceiptService(
            JdbcTemplate jdbc,
            TransactionService transactionService,
            DeliveryService deliveryService,
            Clock clock
    ) {
        this.jdbc = jdbc;
        this.transactionService = transactionService;
        this.deliveryService = deliveryService;
        this.clock = clock;
        // JRXML компилируется один раз при запуске, а не при каждом скачивании.
        this.report = compileTemplate();
    }

    public ReceiptMetadata generate(UUID customerId, UUID transactionId) {
        TransactionService.TransactionRecord transaction = transactionService.findOwned(customerId, transactionId);
        ReceiptDocument existing = findByTransaction(customerId, transactionId);
        if (existing != null) {
            return existing.metadata();
        }

        Customer customer = customer(customerId);
        // PDF формируется JasperReports и сохраняется вместе с SHA-256 для проверки целостности.
        byte[] pdf = render(transaction, customer);
        UUID receiptId = UUID.randomUUID();
        Instant createdAt = clock.instant();
        String fileName = "Mashreq-Receipt-" + transaction.reference() + ".pdf";
        String sha256 = sha256Hex(pdf);

        try {
            jdbc.update("""
                    INSERT INTO receipts (
                        id, customer_id, transaction_id, template_version,
                        file_name, content_type, pdf_data, pdf_sha256, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, receiptId, customerId, transactionId, TEMPLATE_VERSION,
                    fileName, "application/pdf", pdf, sha256, Timestamp.from(createdAt));
        } catch (DuplicateKeyException race) {
            ReceiptDocument winner = findByTransaction(customerId, transactionId);
            if (winner != null) {
                return winner.metadata();
            }
            throw race;
        }
        return new ReceiptMetadata(receiptId, transactionId, transaction.reference(), fileName,
                "application/pdf", sha256, pdf.length, createdAt);
    }

    public ReceiptDocument get(UUID customerId, UUID receiptId) {
        List<ReceiptDocument> rows = jdbc.query("""
                SELECT r.id, r.transaction_id, t.reference, r.file_name,
                       r.content_type, r.pdf_sha256, r.pdf_data, r.created_at
                FROM receipts r
                JOIN banking_transactions t ON t.id = r.transaction_id
                WHERE r.id = ? AND r.customer_id = ?
                """, (rs, rowNum) -> document(rs), receiptId, customerId);
        if (rows.isEmpty()) {
            throw new ApiException(HttpStatus.NOT_FOUND, "RECEIPT_NOT_FOUND", "Receipt was not found");
        }
        return rows.getFirst();
    }

    public List<DeliveryService.DeliveryResult> deliver(
            UUID customerId,
            UUID receiptId,
            List<ReceiptChannel> channels
    ) {
        if (channels.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "CHANNEL_REQUIRED", "At least one delivery channel is required");
        }
        ReceiptDocument receipt = get(customerId, receiptId);
        Customer customer = customer(customerId);
        return channels.stream().distinct().map(channel -> switch (channel) {
            case EMAIL -> deliveryService.sendReceiptEmail(
                    customerId, customer.email(), receipt.metadata().fileName(),
                    receipt.pdf(), receipt.metadata().reference()
            );
            case SMS -> deliveryService.sendSms(
                    customerId,
                    customer.mobileNumber(),
                    "RECEIPT",
                    "Mashreq transfer " + receipt.metadata().reference()
                            + " completed. Download the PDF receipt securely in the app."
            );
        }).toList();
    }

    private ReceiptDocument findByTransaction(UUID customerId, UUID transactionId) {
        List<ReceiptDocument> rows = jdbc.query("""
                SELECT r.id, r.transaction_id, t.reference, r.file_name,
                       r.content_type, r.pdf_sha256, r.pdf_data, r.created_at
                FROM receipts r
                JOIN banking_transactions t ON t.id = r.transaction_id
                WHERE r.transaction_id = ? AND r.customer_id = ?
                """, (rs, rowNum) -> document(rs), transactionId, customerId);
        return rows.isEmpty() ? null : rows.getFirst();
    }

    private ReceiptDocument document(java.sql.ResultSet rs) throws java.sql.SQLException {
        byte[] pdf = rs.getBytes("pdf_data");
        ReceiptMetadata metadata = new ReceiptMetadata(
                rs.getObject("id", UUID.class),
                rs.getObject("transaction_id", UUID.class),
                rs.getString("reference"),
                rs.getString("file_name"),
                rs.getString("content_type"),
                rs.getString("pdf_sha256"),
                pdf.length,
                rs.getTimestamp("created_at").toInstant()
        );
        return new ReceiptDocument(metadata, pdf);
    }

    private byte[] render(TransactionService.TransactionRecord transaction, Customer customer) {
        Map<String, Object> parameters = new LinkedHashMap<>();
        parameters.put("REFERENCE", transaction.reference());
        parameters.put("STATUS", transaction.status().name());
        parameters.put("DATE", DATE_FORMAT.format(transaction.completedAt().atZone(GST)));
        parameters.put("TIME", TIME_FORMAT.format(transaction.completedAt().atZone(GST)));
        parameters.put("TRANSACTION_TYPE", readable(transaction.transactionType().name()));
        parameters.put("CUSTOMER_NAME", customer.firstName() + " " + customer.lastName());
        parameters.put("SENDER_ACCOUNT", maskAccount(transaction.senderAccount()));
        parameters.put("BENEFICIARY_NAME", transaction.beneficiaryName());
        parameters.put("BENEFICIARY_BANK", valueOrDash(transaction.beneficiaryBank()));
        parameters.put("BENEFICIARY_COUNTRY", valueOrDash(transaction.beneficiaryCountry()));
        parameters.put("BENEFICIARY_IBAN", valueOrDash(transaction.beneficiaryIban()));
        parameters.put("SWIFT", valueOrDash(transaction.beneficiarySwift()));
        parameters.put("AMOUNT", money(transaction.currency(), transaction.amount()));
        parameters.put("FEE", money(transaction.currency(), transaction.fee()));
        parameters.put("TOTAL", money(transaction.currency(), transaction.amount().add(transaction.fee())));
        parameters.put("PURPOSE", valueOrDash(transaction.purpose()));

        try {
            JasperPrint print = JasperFillManager.fillReport(report, parameters, new JREmptyDataSource(1));
            return JasperExportManager.exportReportToPdf(print);
        } catch (JRException exception) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "RECEIPT_RENDER_FAILED", "The PDF receipt could not be generated");
        }
    }

    private Customer customer(UUID customerId) {
        return jdbc.queryForObject("""
                SELECT first_name, last_name, email, mobile_number
                FROM customers
                WHERE id = ?
                """, (rs, rowNum) -> new Customer(
                rs.getString("first_name"),
                rs.getString("last_name"),
                rs.getString("email"),
                rs.getString("mobile_number")
        ), customerId);
    }

    private static JasperReport compileTemplate() {
        ClassPathResource resource = new ClassPathResource("reports/fund_transfer_receipt.jrxml");
        try (InputStream input = resource.getInputStream()) {
            return JasperCompileManager.compileReport(input);
        } catch (IOException | JRException exception) {
            throw new IllegalStateException("JasperReports receipt template could not be compiled", exception);
        }
    }

    private static String money(String currency, BigDecimal amount) {
        return currency + " " + String.format(Locale.US, "%,.2f", amount);
    }

    private static String readable(String value) {
        String normalized = value.replace('_', ' ').toLowerCase(Locale.ROOT);
        return Character.toUpperCase(normalized.charAt(0)) + normalized.substring(1);
    }

    private static String valueOrDash(String value) {
        return value == null || value.isBlank() ? "—" : value;
    }

    private static String maskAccount(String account) {
        if (account.length() <= 4) {
            return account;
        }
        return "*".repeat(account.length() - 4) + account.substring(account.length() - 4);
    }

    private static String sha256Hex(byte[] data) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(data));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    public enum ReceiptChannel {
        EMAIL,
        SMS
    }

    public record ReceiptMetadata(
            UUID id,
            UUID transactionId,
            String reference,
            String fileName,
            String contentType,
            String sha256,
            int sizeBytes,
            Instant createdAt
    ) {}

    public record ReceiptDocument(ReceiptMetadata metadata, byte[] pdf) {}

    private record Customer(String firstName, String lastName, String email, String mobileNumber) {}
}
