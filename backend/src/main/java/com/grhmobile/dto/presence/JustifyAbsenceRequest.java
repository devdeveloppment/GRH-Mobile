package com.grhmobile.dto.presence;

import jakarta.validation.constraints.NotBlank;

public record JustifyAbsenceRequest(
    @NotBlank(message = "La justification est obligatoire.")
    String justification,

    String pieceJointe
) {
}
