package com.grhmobile.dto.paie;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record PayrollPeriodRequest(
    @NotNull(message = "Le mois est obligatoire.")
    @Min(value = 1, message = "Le mois doit être compris entre 1 et 12.")
    @Max(value = 12, message = "Le mois doit être compris entre 1 et 12.")
    Integer month,
    @NotNull(message = "L'année est obligatoire.")
    @Min(value = 2020, message = "L'année doit être valide.")
    Integer year
) {
}
