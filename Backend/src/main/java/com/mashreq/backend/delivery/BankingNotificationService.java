package com.mashreq.backend.delivery;

import com.mashreq.backend.transaction.TransactionService;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class BankingNotificationService {
    private final JdbcTemplate jdbc;
    private final DeliveryService deliveryService;

    public BankingNotificationService(JdbcTemplate jdbc, DeliveryService deliveryService) {
        this.jdbc = jdbc;
        this.deliveryService = deliveryService;
    }

    public List<DeliveryService.DeliveryResult> beneficiaryAdded(UUID customerId, String beneficiaryName) {
        Contacts contacts = contacts(customerId);
        String message = "Mashreq: beneficiary " + beneficiaryName + " was added successfully.";
        return List.of(
                deliveryService.sendSms(customerId, contacts.mobileNumber(), "BENEFICIARY_ADDED", message),
                deliveryService.sendNotificationEmail(
                        customerId,
                        contacts.email(),
                        "BENEFICIARY_ADDED",
                        "Beneficiary added",
                        "Dear Customer,\n\n" + message + "\n\nRegards,\nMashreq Team"
                )
        );
    }

    public List<DeliveryService.DeliveryResult> transactionCompleted(
            UUID customerId,
            TransactionService.TransactionRecord transaction
    ) {
        Contacts contacts = contacts(customerId);
        String action = switch (transaction.transactionType()) {
            case LOCAL_TRANSFER, INTERNATIONAL_TRANSFER -> "Transfer completed";
            case ACCOUNT_DEBIT -> "Account debit";
            case ACCOUNT_CREDIT -> "Account credit";
        };
        String message = "Mashreq: " + action + " — " + transaction.currency() + " "
                + transaction.amount().toPlainString() + ". Reference " + transaction.reference() + ".";
        return List.of(
                deliveryService.sendSms(customerId, contacts.mobileNumber(), transaction.transactionType().name(), message),
                deliveryService.sendNotificationEmail(
                        customerId,
                        contacts.email(),
                        transaction.transactionType().name(),
                        action,
                        "Dear Customer,\n\n" + message + "\n\nRegards,\nMashreq Team"
                )
        );
    }

    private Contacts contacts(UUID customerId) {
        return jdbc.queryForObject("""
                SELECT email, mobile_number
                FROM customers
                WHERE id = ?
                """, (rs, rowNum) -> new Contacts(
                rs.getString("email"),
                rs.getString("mobile_number")
        ), customerId);
    }

    private record Contacts(String email, String mobileNumber) {}
}
