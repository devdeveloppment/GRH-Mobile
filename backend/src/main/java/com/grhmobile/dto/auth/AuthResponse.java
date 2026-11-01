package com.grhmobile.dto.auth;

public record AuthResponse(
    String token,
    String role,
    UserDto user,
    java.util.List<String> permissions,
    boolean autoLogout
) {
}
