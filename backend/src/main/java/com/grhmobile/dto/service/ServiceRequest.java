package com.grhmobile.dto.service;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record ServiceRequest(
    @NotBlank String nom,
    @NotBlank String description,
    @NotNull Long responsableId
) {}
