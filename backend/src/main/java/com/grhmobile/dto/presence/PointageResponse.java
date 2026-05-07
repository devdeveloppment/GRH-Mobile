package com.grhmobile.dto.presence;

import java.time.LocalDateTime;

public record PointageResponse(
    Long id,
    String type,
    LocalDateTime heure,
    String statut
) {
    public static PointageResponse success(Long id, String type, LocalDateTime heure) {
        return new PointageResponse(id, type, heure, "OK");
    }
}
