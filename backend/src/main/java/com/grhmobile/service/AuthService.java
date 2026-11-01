package com.grhmobile.service;

import com.grhmobile.repository.AppSettingRepository;
import com.grhmobile.security.AccessControlService;
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
    private final AccessControlService acl;
    private final AppSettingRepository appSettingRepository;

    public AuthService(
        AuthenticationManager authenticationManager,
        UtilisateurRepository utilisateurRepository,
        JwtService jwtService,
        AccessControlService acl,
        AppSettingRepository appSettingRepository
    ) {
        this.acl = acl;
        this.appSettingRepository = appSettingRepository;
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
        return new AuthResponse(token, utilisateur.getRole().name(), UserDto.fromEntity(utilisateur),
            acl.permissionsOf(utilisateur), autoLogoutEnabled());
    }

    public java.util.Map<String, Object> currentSession() {
        Utilisateur utilisateur = acl.currentUser()
            .flatMap(u -> utilisateurRepository.findById(u.getId()))
            .orElseThrow(() -> new org.springframework.security.authentication.BadCredentialsException("Session invalide."));
        return java.util.Map.of(
            "role", utilisateur.getRole().name(),
            "user", UserDto.fromEntity(utilisateur),
            "permissions", acl.permissionsOf(utilisateur),
            "autoLogout", autoLogoutEnabled()
        );
    }

    public boolean autoLogoutEnabled() {
        return appSettingRepository.findByKey("AUTO_LOGOUT").map(s -> s.isEnabled()).orElse(true);
    }
}
