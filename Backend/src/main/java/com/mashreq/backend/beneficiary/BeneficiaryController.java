package com.mashreq.backend.beneficiary;

import com.mashreq.backend.auth.AuthenticatedCustomer;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/v1/beneficiaries")
public class BeneficiaryController {
    private final BeneficiaryService beneficiaryService;

    public BeneficiaryController(BeneficiaryService beneficiaryService) {
        this.beneficiaryService = beneficiaryService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BeneficiaryService.Beneficiary create(
            HttpServletRequest servletRequest,
            @Valid @RequestBody CreateBeneficiaryRequest request
    ) {
        return beneficiaryService.create(
                AuthenticatedCustomer.id(servletRequest),
                new BeneficiaryService.CreateBeneficiary(
                        request.nickname(), request.fullName(), request.bankName(),
                        request.country(), request.swiftCode(), request.iban()
                )
        );
    }

    @GetMapping
    public List<BeneficiaryService.Beneficiary> list(HttpServletRequest servletRequest) {
        return beneficiaryService.list(AuthenticatedCustomer.id(servletRequest));
    }

    public record CreateBeneficiaryRequest(
            @NotBlank @Size(max = 100) String nickname,
            @NotBlank @Size(max = 200) String fullName,
            @NotBlank @Size(max = 200) String bankName,
            @NotBlank @Size(max = 100) String country,
            @Size(max = 20) String swiftCode,
            @NotBlank
            @Pattern(regexp = "^[A-Za-z]{2}[A-Za-z0-9 ]{13,32}$", message = "must be a valid IBAN")
            String iban
    ) {}
}
