package com.grhmobile.controller;

import org.springframework.web.bind.annotation.GetMapping;
import java.util.Map;
import com.grhmobile.dto.auth.AuthRequest;
import com.grhmobile.dto.auth.AuthResponse;
import com.grhmobile.service.AuthService;

import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /** Session courante : profil, permissions effectives et règles de session. */
    @GetMapping("/me")
    public Map<String, Object> me() {
        return authService.currentSession();
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody AuthRequest request) {
        return authService.login(request);
    }
}
