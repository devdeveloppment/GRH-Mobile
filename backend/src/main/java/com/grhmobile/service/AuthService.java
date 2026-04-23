package com.grhmobile.service;

import com.grhmobile.dto.auth.AuthRequest;
import com.grhmobile.dto.auth.AuthResponse;
import com.grhmobile.dto.auth.UserDto;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.repository.UtilisateurRepository;
import com.grhmobile.security.JwtService;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final UtilisateurRepository utilisateurRepository;
    private final JwtService jwtService;

    public AuthService(
        AuthenticationManager authenticationManager,
        UtilisateurRepository utilisateurRepository,
        JwtService jwtService
    ) {
        this.authenticationManager = authenticationManager;
        this.utilisateurRepository = utilisateurRepository;
        this.jwtService = jwtService;
    }

    public AuthResponse login(AuthRequest request) {
        authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(request.email(), request.password())
        );

        Utilisateur utilisateur = utilisateurRepository.findByEmailIgnoreCase(request.email())
            .orElseThrow();

        String token = jwtService.generateToken(utilisateur);
        return new AuthResponse(token, utilisateur.getRole().name(), UserDto.fromEntity(utilisateur));
    }
}
