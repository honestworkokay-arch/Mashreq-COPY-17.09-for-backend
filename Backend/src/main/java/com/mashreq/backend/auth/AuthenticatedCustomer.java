package com.mashreq.backend.auth;

import com.mashreq.backend.api.ApiException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public final class AuthenticatedCustomer {
    public static final String REQUEST_ATTRIBUTE = "authenticatedCustomerId";

    private AuthenticatedCustomer() {}

    public static UUID id(HttpServletRequest request) {
        Object value = request.getAttribute(REQUEST_ATTRIBUTE);
        if (value instanceof UUID id) {
            return id;
        }
        throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "A valid bearer token is required");
    }
}
