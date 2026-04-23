package com.grhmobile.dto.conge;

import java.time.LocalDate;

import com.grhmobile.entity.Conge;

public record CongeResponse(
    Long id,
    Long employeId,
    String typeConge,
    LocalDate dateDebut,
    LocalDate dateFin,
    Integer nombreJours,
    String statut,
    String motif,
    String commentaire,
    String nomEmploye
) {

    public static CongeResponse fromEntity(Conge conge) {
        return new CongeResponse(
            conge.getId(),
            conge.getEmploye().getId(),
            conge.getTypeConge().name(),
            conge.getDateDebut(),
            conge.getDateFin(),
            conge.getNombreJours(),
            conge.getStatut().name(),
            conge.getMotif(),
            conge.getCommentaire(),
            conge.getEmploye().getPrenom() + " " + conge.getEmploye().getNom()
        );
    }
}
