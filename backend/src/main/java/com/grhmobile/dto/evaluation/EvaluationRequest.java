package com.grhmobile.dto.evaluation;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record EvaluationRequest(
    @NotNull(message = "L'employé est obligatoire.")
    Long employeId,

    @NotBlank(message = "La période est obligatoire.")
    String periode,

    @NotNull @Min(0) @Max(20)
    Integer note,

    String commentaire,
    String type,
    BigDecimal noteCompetences,
    BigDecimal noteObjectifs,
    BigDecimal noteComportement
) {}
