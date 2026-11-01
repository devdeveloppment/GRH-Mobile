package com.grhmobile.dto.audit;

import com.grhmobile.entity.AuditLog;

import java.time.OffsetDateTime;

public record AuditLogResponse(
        Long id,
        Long acteurId,
        String acteurNom,
        String acteurEmail,
        String action,
        String entite,
        Long entiteId,
        String avant,
        String apres,
        String ipAddress,
        OffsetDateTime createdAt) {
    public static AuditLogResponse fromEntity(AuditLog a) {
        var acteur = a.getActeur();
        return new AuditLogResponse(
                a.getId(),
                acteur != null ? acteur.getId() : null,
                acteur != null ? acteur.getPrenom() + " " + acteur.getNom() : "Utilisateur supprimé",
                acteur != null ? acteur.getEmail() : null,
                a.getAction(),
                a.getEntite(),
                a.getEntiteId(),
                a.getAvant(),
                a.getApres(),
                a.getIpAddress(),
                a.getCreatedAt());
    }
}
