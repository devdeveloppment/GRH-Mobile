package com.grhmobile.dto.presence;

import jakarta.validation.constraints.NotNull;

public record PointageRequest(
    @NotNull(message = "Le type de pointage est obligatoire.")
    String type,
    
    @NotNull(message = "La latitude est obligatoire.")
    Double latitude,
    
    @NotNull(message = "La longitude est obligatoire.")
    Double longitude
) {
}
