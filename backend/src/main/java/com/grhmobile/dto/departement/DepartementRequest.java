package com.grhmobile.dto.departement;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record DepartementRequest(
    @NotBlank(message = "Le code est obligatoire.")
    @Size(max = 50)
    String code,

    @NotBlank(message = "Le nom est obligatoire.")
    String nom,

    String description,
    Long parentId,
    Long managerId
) {}
