package com.grhmobile.dto.departement;

import com.grhmobile.entity.Departement;

import java.util.List;

public record DepartementResponse(
    Long id,
    String code,
    String nom,
    String description,
    Long parentId,
    String parentNom,
    Long managerId,
    String managerNom,
    boolean actif,
    List<DepartementResponse> sousDepartements
) {
    public static DepartementResponse fromEntity(Departement d) {
        return fromEntity(d, false);
    }

    public static DepartementResponse fromEntity(Departement d, boolean withChildren) {
        List<DepartementResponse> children = withChildren
            ? d.getSousDepartements().stream()
                .filter(Departement::isActif)
                .map(c -> fromEntity(c, true))
                .toList()
            : List.of();

        return new DepartementResponse(
            d.getId(),
            d.getCode(),
            d.getNom(),
            d.getDescription(),
            d.getParent() != null ? d.getParent().getId() : null,
            d.getParent() != null ? d.getParent().getNom() : null,
            d.getManager() != null ? d.getManager().getId() : null,
            d.getManager() != null ? d.getManager().getPrenom() + " " + d.getManager().getNom() : null,
            d.isActif(),
            children
        );
    }
}
