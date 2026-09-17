package com.mashreq.backend.auth;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/auth")
public class AuthController {
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthService.AuthResult register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(new AuthService.RegistrationData(
                request.firstName(),
                request.lastName(),
                request.mobileNumber(),
                request.email(),
                request.iban(),
                request.accountNumber(),
                request.password()
        ));
    }

    @PostMapping("/login")
    public AuthService.AuthResult login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request.email(), request.password());
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@RequestHeader("Authorization") String authorization) {
        authService.revoke(authorization.substring("Bearer ".length()).trim());
    }

    public record RegisterRequest(
            @NotBlank @Size(max = 100) String firstName,
            @NotBlank @Size(max = 100) String lastName,
            @NotBlank
            @Pattern(regexp = "^\\+[1-9][0-9]{7,14}$", message = "must use E.164 format, for example +971501234567")
            String mobileNumber,
            @NotBlank @Email @Size(max = 320) String email,
            @NotBlank
            @Pattern(regexp = "^[A-Za-z]{2}[A-Za-z0-9 ]{13,32}$", message = "must be a valid IBAN")
            String iban,
            @NotBlank @Size(max = 64) String accountNumber,
            @NotBlank @Size(min = 12, max = 128) String password
    ) {}

    public record LoginRequest(
            @NotBlank @Email @Size(max = 320) String email,
            @NotBlank @Size(max = 128) String password
    ) {}
}
