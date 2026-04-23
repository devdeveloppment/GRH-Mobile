package com.grhmobile.security;

import com.grhmobile.entity.Utilisateur;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.UtilisateurRepository;

import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Service;

@Service
public class UserPrincipalService implements UserDetailsService {

    private final UtilisateurRepository utilisateurRepository;

    public UserPrincipalService(UtilisateurRepository utilisateurRepository) {
        this.utilisateurRepository = utilisateurRepository;
    }

    @Override
    public UserPrincipal loadUserByUsername(String username) {
        Utilisateur utilisateur = utilisateurRepository.findByEmailIgnoreCase(username)
            .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));
        return new UserPrincipal(utilisateur);
    }
}
