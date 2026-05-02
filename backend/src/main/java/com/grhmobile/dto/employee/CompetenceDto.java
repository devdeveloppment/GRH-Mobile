package com.grhmobile.dto.employee;

import com.grhmobile.entity.Competence;

public record CompetenceDto(Long id, String libelle, int niveau) {
    public static CompetenceDto fromEntity(Competence c) {
        return new CompetenceDto(c.getId(), c.getLibelle(), c.getNiveau());
    }
}
