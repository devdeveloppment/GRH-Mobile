package com.grhmobile.dto.presence;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.grhmobile.entity.Presence;

public record PresenceResponse(
    Long id,
    Long employeId,
    LocalDate date,
    LocalDateTime heureArrivee,
    LocalDateTime heureDepart,
    String statut
) {

    public static PresenceResponse fromEntity(Presence presence) {
        return new PresenceResponse(
            presence.getId(),
            presence.getEmploye().getId(),
            presence.getDate(),
            presence.getHeureArrivee(),
            presence.getHeureDepart(),
            presence.getStatut().name()
        );
    }
}
