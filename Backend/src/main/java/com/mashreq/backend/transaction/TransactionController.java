package com.mashreq.backend.transaction;

import com.mashreq.backend.auth.AuthenticatedCustomer;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/v1/transactions")
public class TransactionController {
    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TransactionService.TransactionRecord create(
            HttpServletRequest servletRequest,
            @Valid @RequestBody CreateTransactionRequest request
    ) {
        return transactionService.create(
                AuthenticatedCustomer.id(servletRequest),
                new TransactionService.CreateTransaction(
                        request.clientRequestId(),
                        request.transactionType(),
                        request.beneficiaryName(),
                        request.beneficiaryBank(),
                        request.beneficiaryCountry(),
                        request.beneficiarySwift(),
                        request.beneficiaryIban(),
                        request.senderAccount(),
                        request.currency(),
                        request.amount(),
                        request.fee() == null ? BigDecimal.ZERO : request.fee(),
                        request.purpose()
                )
        );
    }

    @GetMapping
    public List<TransactionService.TransactionRecord> list(
            HttpServletRequest servletRequest,
            @RequestParam(defaultValue = "50") int limit
    ) {
        return transactionService.list(AuthenticatedCustomer.id(servletRequest), limit);
    }

    @GetMapping("/{transactionId}")
    public TransactionService.TransactionRecord get(
            HttpServletRequest servletRequest,
            @PathVariable UUID transactionId
    ) {
        return transactionService.findOwned(AuthenticatedCustomer.id(servletRequest), transactionId);
    }

    public record CreateTransactionRequest(
            @NotNull UUID clientRequestId,
            @NotNull TransactionService.Type transactionType,
            @NotBlank @Size(max = 200) String beneficiaryName,
            @Size(max = 200) String beneficiaryBank,
            @Size(max = 100) String beneficiaryCountry,
            @Size(max = 20) String beneficiarySwift,
            @Size(max = 34) String beneficiaryIban,
            @NotBlank @Size(max = 64) String senderAccount,
            @NotBlank @Pattern(regexp = "^[A-Za-z]{3}$") String currency,
            @NotNull @DecimalMin(value = "0.01") BigDecimal amount,
            @DecimalMin(value = "0.00") BigDecimal fee,
            @Size(max = 200) String purpose
    ) {}
}
