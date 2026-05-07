package com.grhmobile.dto.admin;

import com.grhmobile.entity.Utilisateur;
import java.time.OffsetDateTime;

public record UserDto(
    Long id,
    String nom,
    String prenom,
    String email,
    String role,
    boolean actif,
    OffsetDateTime dateCreation,
    String photoUrl
) {
    public static UserDto fromEntity(Utilisateur u) {
        return new UserDto(u.getId(), u.getNom(), u.getPrenom(), u.getEmail(),
                u.getRole().name(), u.isActif(), u.getDateCreation(), u.getPhotoUrl());
    }
}
