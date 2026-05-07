package com.grhmobile.dto.presence;

import java.time.LocalDate;

import com.grhmobile.entity.Presence;

public record ReportAbsenceResponse(
    Long id,
    LocalDate date,
    String motif,
    String statut
) {
    public static ReportAbsenceResponse fromEntity(Presence presence) {
        return new ReportAbsenceResponse(
            presence.getId(),
            presence.getDate(),
            presence.getMotifAbsence(),
            presence.getStatut().name()
        );
    }
}
