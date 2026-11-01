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

    /** Déconnexion : le jeton présenté est révoqué immédiatement (toutes instances). */
    @PostMapping("/logout")
    @org.springframework.web.bind.annotation.ResponseStatus(org.springframework.http.HttpStatus.NO_CONTENT)
    public void logout(@org.springframework.web.bind.annotation.RequestHeader("Authorization") String authorization) {
        authService.logout(authorization.substring(7));
    }

    /** Déconnecte toutes les sessions de l'utilisateur courant (tous appareils). */
    @PostMapping("/logout-all")
    @org.springframework.web.bind.annotation.ResponseStatus(org.springframework.http.HttpStatus.NO_CONTENT)
    public void logoutAll() {
        authService.logoutAll();
    }
}
