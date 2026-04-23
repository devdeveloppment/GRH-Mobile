package com.grhmobile.dto.conge;

import java.time.LocalDate;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CongeRequest(
    @NotBlank(message = "Le type de congé est obligatoire.")
    String typeConge,
    @NotNull(message = "La date de début est obligatoire.")
    LocalDate dateDebut,
    @NotNull(message = "La date de fin est obligatoire.")
    LocalDate dateFin,
    Integer nombreJours,
    String motif
) {
}
