package com.grhmobile.dto.recrutement;

import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;

public record EntretienRequest(
    @NotNull(message = "La date et heure sont obligatoires.")
    OffsetDateTime dateHeure,

    String type,
    Long intervieweurId
) {}
