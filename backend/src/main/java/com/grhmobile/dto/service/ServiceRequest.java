package com.grhmobile.dto.service;

import jakarta.validation.constraints.NotBlank;

public record ServiceRequest(
    @NotBlank String nom,
    @NotBlank String description,
    @NotBlank String responsable
) {}
