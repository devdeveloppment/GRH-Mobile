package com.grhmobile.dto.formation;

import com.grhmobile.entity.Formation;

import java.math.BigDecimal;
import java.time.LocalDate;

public record FormationResponse(
    Long id,
    String titre,
    String description,
    String type,
    String formateur,
    Integer dureeHeures,
    String statut,
    LocalDate dateDebut,
    LocalDate dateFin,
    BigDecimal budget,
    int nbParticipants
) {
    public static FormationResponse fromEntity(Formation f) {
        return new FormationResponse(
            f.getId(),
            f.getTitre(),
            f.getDescription(),
            f.getType(),
            f.getFormateur(),
            f.getDureeHeures(),
            f.getStatut(),
            f.getDateDebut(),
            f.getDateFin(),
            f.getBudget(),
            f.getParticipations().size()
        );
    }
}
