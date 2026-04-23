package com.grhmobile.dto.auth;

import com.grhmobile.entity.Utilisateur;

public record UserDto(
    Long id,
    String nom,
    String prenom,
    String email,
    String role,
    boolean actif,
    String dateCreation
) {

    public static UserDto fromEntity(Utilisateur utilisateur) {
        return new UserDto(
            utilisateur.getId(),
            utilisateur.getNom(),
            utilisateur.getPrenom(),
            utilisateur.getEmail(),
            utilisateur.getRole().name(),
            utilisateur.isActif(),
            utilisateur.getDateCreation() != null ? utilisateur.getDateCreation().toString() : null
        );
    }
}
