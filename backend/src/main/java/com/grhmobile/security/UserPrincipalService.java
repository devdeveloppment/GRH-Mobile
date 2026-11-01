package com.grhmobile.security;

import com.grhmobile.entity.Utilisateur;
import com.grhmobile.repository.UtilisateurRepository;

import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Service;

@Service
public class UserPrincipalService implements UserDetailsService {

    private final UtilisateurRepository utilisateurRepository;

    public UserPrincipalService(UtilisateurRepository utilisateurRepository) {
        this.utilisateurRepository = utilisateurRepository;
    }

    /** Compte inconnu : même réponse (401) qu'un mauvais mot de passe, pour ne pas révéler les comptes existants. */
    @Override
    public UserPrincipal loadUserByUsername(String username) {
        Utilisateur utilisateur = utilisateurRepository.findByEmailIgnoreCase(username)
            .orElseThrow(() -> new org.springframework.security.core.userdetails.UsernameNotFoundException("Utilisateur introuvable."));
        return new UserPrincipal(utilisateur);
    }
}
