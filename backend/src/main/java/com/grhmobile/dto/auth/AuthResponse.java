package com.grhmobile.dto.auth;

public record AuthResponse(
    String token,
    String role,
    UserDto user
) {
}
