package com.mashreq.backend.otp;

import com.mashreq.backend.auth.AuthenticatedCustomer;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/v1/otp")
public class OtpController {
    private final OtpService otpService;

    public OtpController(OtpService otpService) {
        this.otpService = otpService;
    }

    @PostMapping("/send")
    @ResponseStatus(HttpStatus.CREATED)
    public OtpService.ChallengeResponse send(
            HttpServletRequest servletRequest,
            @Valid @RequestBody SendOtpRequest request
    ) {
        return otpService.send(
                AuthenticatedCustomer.id(servletRequest),
                request.purpose(),
                request.channels()
        );
    }

    @PostMapping("/verify")
    public OtpService.VerificationResponse verify(
            HttpServletRequest servletRequest,
            @Valid @RequestBody VerifyOtpRequest request
    ) {
        return otpService.verify(
                AuthenticatedCustomer.id(servletRequest),
                request.challengeId(),
                request.code()
        );
    }

    public record SendOtpRequest(
            @NotNull OtpService.Purpose purpose,
            @NotEmpty List<@NotNull OtpService.Channel> channels
    ) {}

    public record VerifyOtpRequest(
            @NotNull UUID challengeId,
            @NotBlank @Pattern(regexp = "^[0-9]{6}$") String code
    ) {}
}
