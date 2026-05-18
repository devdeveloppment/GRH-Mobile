package com.grhmobile.dto.contrat;

import com.grhmobile.entity.Contrat;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

public record ContratResponse(
    Long id,
    Long employeId,
    String employeNom,
    String typeContrat,
    LocalDate dateDebut,
    LocalDate dateFin,
    BigDecimal salaireBrut,
    Long posteId,
    String posteIntitule,
    Long departementId,
    String departementNom,
    String statut,
    String documentUrl,
    OffsetDateTime createdAt
) {
    public static ContratResponse fromEntity(Contrat c) {
        return new ContratResponse(
            c.getId(),
            c.getEmploye().getId(),
            c.getEmploye().getPrenom() + " " + c.getEmploye().getNom(),
            c.getTypeContrat(),
            c.getDateDebut(),
            c.getDateFin(),
            c.getSalaireBrut(),
            c.getPoste() != null ? c.getPoste().getId() : null,
            c.getPoste() != null ? c.getPoste().getIntitule() : null,
            c.getDepartement() != null ? c.getDepartement().getId() : null,
            c.getDepartement() != null ? c.getDepartement().getNom() : null,
            c.getStatut(),
            c.getDocumentUrl(),
            c.getCreatedAt()
        );
    }
}
