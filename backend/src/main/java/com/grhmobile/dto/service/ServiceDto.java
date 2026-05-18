package com.grhmobile.dto.service;

import com.grhmobile.entity.Employe;
import com.grhmobile.entity.ServiceEntity;

public record ServiceDto(
    Long id,
    String nom,
    String description,
    String responsable,
    boolean actif,
    long nombreEmployes,
    Long responsableId,
    String responsableNom
) {
    public static ServiceDto fromEntity(ServiceEntity s, long count) {
        Employe resp = s.getResponsableEmploye();
        String nomAffiche = resp != null
            ? resp.getPrenom() + " " + resp.getNom()
            : (s.getResponsable() != null ? s.getResponsable() : "");
        return new ServiceDto(
            s.getId(), s.getNom(), s.getDescription(),
            nomAffiche, s.isActif(), count,
            resp != null ? resp.getId() : null,
            nomAffiche
        );
    }
}
