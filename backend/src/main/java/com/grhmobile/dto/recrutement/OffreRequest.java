package com.grhmobile.dto.recrutement;

import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

public record OffreRequest(
    @NotBlank(message = "Le titre est obligatoire.")
    String titre,

    String description,
    Long posteId,
    Long departementId,
    LocalDate dateLimite
) {}
