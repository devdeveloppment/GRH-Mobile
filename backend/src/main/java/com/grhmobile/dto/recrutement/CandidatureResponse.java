package com.grhmobile.dto.recrutement;

import com.grhmobile.entity.Candidature;

import java.time.OffsetDateTime;

public record CandidatureResponse(
    Long id,
    Long offreId,
    String offreTitre,
    String nom,
    String prenom,
    String email,
    String telephone,
    String cvUrl,
    boolean hasCv,
    String cvNomFichier,
    String lettreMotivation,
    String statut,
    Integer note,
    String commentaire,
    OffsetDateTime createdAt
) {
    public static CandidatureResponse fromEntity(Candidature c) {
        return new CandidatureResponse(
            c.getId(),
            c.getOffre().getId(),
            c.getOffre().getTitre(),
            c.getNom(),
            c.getPrenom(),
            c.getEmail(),
            c.getTelephone(),
            c.getCvUrl(),
            c.getCvPath() != null,
            c.getCvNomFichier(),
            c.getLettreMotivation(),
            c.getStatut(),
            c.getNote(),
            c.getCommentaire(),
            c.getCreatedAt()
        );
    }
}
