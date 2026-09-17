package com.mashreq.backend.receipt;

import com.mashreq.backend.auth.AuthenticatedCustomer;
import com.mashreq.backend.delivery.DeliveryService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/v1")
public class ReceiptController {
    private final ReceiptService receiptService;

    public ReceiptController(ReceiptService receiptService) {
        this.receiptService = receiptService;
    }

    @PostMapping("/transactions/{transactionId}/receipt")
    @ResponseStatus(HttpStatus.CREATED)
    public ReceiptService.ReceiptMetadata generate(
            HttpServletRequest servletRequest,
            @PathVariable UUID transactionId
    ) {
        return receiptService.generate(AuthenticatedCustomer.id(servletRequest), transactionId);
    }

    @GetMapping("/receipts/{receiptId}")
    public ReceiptService.ReceiptMetadata metadata(
            HttpServletRequest servletRequest,
            @PathVariable UUID receiptId
    ) {
        return receiptService.get(AuthenticatedCustomer.id(servletRequest), receiptId).metadata();
    }

    @GetMapping("/receipts/{receiptId}/pdf")
    public ResponseEntity<byte[]> pdf(
            HttpServletRequest servletRequest,
            @PathVariable UUID receiptId
    ) {
        ReceiptService.ReceiptDocument document =
                receiptService.get(AuthenticatedCustomer.id(servletRequest), receiptId);
        ContentDisposition disposition = ContentDisposition.attachment()
                .filename(document.metadata().fileName(), StandardCharsets.UTF_8)
                .build();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, disposition.toString())
                .header("X-Content-SHA256", document.metadata().sha256())
                .contentType(MediaType.APPLICATION_PDF)
                .contentLength(document.pdf().length)
                .body(document.pdf());
    }

    @PostMapping("/receipts/{receiptId}/deliver")
    public List<DeliveryService.DeliveryResult> deliver(
            HttpServletRequest servletRequest,
            @PathVariable UUID receiptId,
            @Valid @RequestBody DeliverReceiptRequest request
    ) {
        return receiptService.deliver(
                AuthenticatedCustomer.id(servletRequest),
                receiptId,
                request.channels()
        );
    }

    public record DeliverReceiptRequest(
            @NotEmpty List<@NotNull ReceiptService.ReceiptChannel> channels
    ) {}
}
