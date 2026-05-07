package com.grhmobile.dto.presence;

import java.time.LocalDate;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record ReportAbsenceRequest(
    @NotNull(message = "La date d'absence est obligatoire.")
    LocalDate date,

    @NotBlank(message = "Le motif d'absence est obligatoire.")
    String motif
) {
}
