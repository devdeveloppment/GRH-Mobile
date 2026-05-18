package com.grhmobile.dto.formation;

import jakarta.validation.constraints.NotBlank;

import java.math.BigDecimal;
import java.time.LocalDate;

public record FormationRequest(
    @NotBlank(message = "Le titre est obligatoire.")
    String titre,

    String description,
    String type,
    String formateur,
    Integer dureeHeures,
    LocalDate dateDebut,
    LocalDate dateFin,
    BigDecimal budget
) {}
