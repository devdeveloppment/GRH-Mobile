package com.grhmobile.dto.poste;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record PosteRequest(
    @NotBlank(message = "Le code est obligatoire.")
    @Size(max = 50)
    String code,

    @NotBlank(message = "L'intitulé est obligatoire.")
    String intitule,

    Long departementId,
    String niveau,
    BigDecimal salaireMin,
    BigDecimal salaireMax,
    String description
) {}
