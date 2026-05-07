package com.grhmobile.dto.presence;

import com.grhmobile.entity.Presence;

public record JustifyAbsenceResponse(
    Long id,
    String statut
) {
    public static JustifyAbsenceResponse fromEntity(Presence presence) {
        return new JustifyAbsenceResponse(
            presence.getId(),
            presence.getStatut().name()
        );
    }
}
