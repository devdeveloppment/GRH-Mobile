package com.grhmobile.dto.evaluation;

import com.grhmobile.entity.Evaluation;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public record EvaluationResponse(
    Long id,
    Long employeId,
    String employeNom,
    Long evaluateurId,
    String evaluateurNom,
    String periode,
    int note,
    String commentaire,
    String type,
    String statut,
    BigDecimal noteCompetences,
    BigDecimal noteObjectifs,
    BigDecimal noteComportement,
    OffsetDateTime createdAt
) {
    public static EvaluationResponse fromEntity(Evaluation e) {
        return new EvaluationResponse(
            e.getId(),
            e.getEmploye().getId(),
            e.getEmploye().getPrenom() + " " + e.getEmploye().getNom(),
            e.getEvaluateur() != null ? e.getEvaluateur().getId() : null,
            e.getEvaluateur() != null ? e.getEvaluateur().getPrenom() + " " + e.getEvaluateur().getNom() : null,
            e.getPeriode(),
            e.getNote(),
            e.getCommentaire(),
            e.getType(),
            e.getStatut(),
            e.getNoteCompetences(),
            e.getNoteObjectifs(),
            e.getNoteComportement(),
            e.getCreatedAt()
        );
    }
}
