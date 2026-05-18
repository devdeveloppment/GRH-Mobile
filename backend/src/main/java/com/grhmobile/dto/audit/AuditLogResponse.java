package com.grhmobile.dto.audit;

import com.grhmobile.entity.AuditLog;

import java.time.OffsetDateTime;

public record AuditLogResponse(
    Long id,
    Long acteurId,
    String acteurNom,
    String action,
    String entite,
    Long entiteId,
    String avant,
    String apres,
    String ipAddress,
    OffsetDateTime createdAt
) {
    public static AuditLogResponse fromEntity(AuditLog a) {
        return new AuditLogResponse(
            a.getId(),
            a.getActeur() != null ? a.getActeur().getId() : null,
            a.getActeur() != null ? a.getActeur().getPrenom() + " " + a.getActeur().getNom() : "Système",
            a.getAction(),
            a.getEntite(),
            a.getEntiteId(),
            a.getAvant(),
            a.getApres(),
            a.getIpAddress(),
            a.getCreatedAt()
        );
    }
}
