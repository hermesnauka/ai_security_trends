package com.securevision.dto;

public record LoginResponse(String token, String tokenType, String role) {

    public static LoginResponse bearer(String token, String role) {
        return new LoginResponse(token, "Bearer", role);
    }
}
