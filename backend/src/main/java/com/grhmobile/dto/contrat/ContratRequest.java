package com.grhmobile.dto.contrat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;

public record ContratRequest(
    @NotBlank(message = "Le type de contrat est obligatoire.")
    String typeContrat,

    @NotNull(message = "La date de début est obligatoire.")
    LocalDate dateDebut,

    LocalDate dateFin,

    @NotNull(message = "Le salaire brut est obligatoire.")
    BigDecimal salaireBrut,

    Long posteId,
    Long departementId,
    String documentUrl
) {}
