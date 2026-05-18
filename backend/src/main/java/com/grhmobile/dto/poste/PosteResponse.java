package com.grhmobile.dto.poste;

import com.grhmobile.entity.Poste;

import java.math.BigDecimal;

public record PosteResponse(
    Long id,
    String code,
    String intitule,
    Long departementId,
    String departementNom,
    String niveau,
    BigDecimal salaireMin,
    BigDecimal salaireMax,
    String description,
    boolean actif
) {
    public static PosteResponse fromEntity(Poste p) {
        return new PosteResponse(
            p.getId(),
            p.getCode(),
            p.getIntitule(),
            p.getDepartement() != null ? p.getDepartement().getId() : null,
            p.getDepartement() != null ? p.getDepartement().getNom() : null,
            p.getNiveau(),
            p.getSalaireMin(),
            p.getSalaireMax(),
            p.getDescription(),
            p.isActif()
        );
    }
}
