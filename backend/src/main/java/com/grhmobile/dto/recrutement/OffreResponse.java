package com.grhmobile.dto.recrutement;

import com.grhmobile.entity.OffreEmploi;

import java.time.LocalDate;
import java.time.OffsetDateTime;

public record OffreResponse(
    Long id,
    String titre,
    String description,
    Long posteId,
    String posteIntitule,
    Long departementId,
    String departementNom,
    String statut,
    LocalDate dateLimite,
    int nbCandidatures,
    OffsetDateTime createdAt
) {
    public static OffreResponse fromEntity(OffreEmploi o) {
        return new OffreResponse(
            o.getId(),
            o.getTitre(),
            o.getDescription(),
            o.getPoste() != null ? o.getPoste().getId() : null,
            o.getPoste() != null ? o.getPoste().getIntitule() : null,
            o.getDepartement() != null ? o.getDepartement().getId() : null,
            o.getDepartement() != null ? o.getDepartement().getNom() : null,
            o.getStatut(),
            o.getDateLimite(),
            o.getCandidatures().size(),
            o.getCreatedAt()
        );
    }
}
