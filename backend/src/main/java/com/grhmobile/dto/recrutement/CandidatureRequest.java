package com.grhmobile.dto.recrutement;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record CandidatureRequest(
    @NotBlank String nom,
    @NotBlank String prenom,
    @NotBlank @Email String email,
    String telephone,
    String lettreMotivation,
    String cvUrl
) {}
