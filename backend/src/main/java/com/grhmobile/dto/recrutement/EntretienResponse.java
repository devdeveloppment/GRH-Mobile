package com.grhmobile.dto.recrutement;

import com.grhmobile.entity.Entretien;

import java.time.OffsetDateTime;

public record EntretienResponse(
    Long id,
    Long candidatureId,
    Long intervieweurId,
    String intervieweurNom,
    OffsetDateTime dateHeure,
    String type,
    Integer note,
    String compteRendu,
    String statut
) {
    public static EntretienResponse fromEntity(Entretien e) {
        return new EntretienResponse(
            e.getId(),
            e.getCandidature().getId(),
            e.getIntervieweur() != null ? e.getIntervieweur().getId() : null,
            e.getIntervieweur() != null ? e.getIntervieweur().getPrenom() + " " + e.getIntervieweur().getNom() : null,
            e.getDateHeure(),
            e.getType(),
            e.getNote(),
            e.getCompteRendu(),
            e.getStatut()
        );
    }
}
