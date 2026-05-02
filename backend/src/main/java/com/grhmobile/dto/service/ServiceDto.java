package com.grhmobile.dto.service;

import com.grhmobile.entity.ServiceEntity;

public record ServiceDto(
    Long id,
    String nom,
    String description,
    String responsable,
    boolean actif,
    long nombreEmployes
) {
    public static ServiceDto fromEntity(ServiceEntity s, long count) {
        return new ServiceDto(s.getId(), s.getNom(), s.getDescription(),
                s.getResponsable(), s.isActif(), count);
    }
}
