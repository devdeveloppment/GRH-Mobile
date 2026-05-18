package com.grhmobile.dto.notification;

import com.grhmobile.entity.Notification;

public record NotificationDto(
    Long id,
    String titre,
    String message,
    String type,
    boolean read,
    String date,
    String redirectTo,
    String readAt
) {
    public static NotificationDto fromEntity(Notification n) {
        return new NotificationDto(
            n.getId(),
            n.getTitre(),
            n.getMessage(),
            n.getType(),
            n.isLu(),
            n.getCreatedAt() != null ? n.getCreatedAt().toInstant().toString() : null,
            n.getRedirectTo(),
            n.getReadAt() != null ? n.getReadAt().toInstant().toString() : null
        );
    }
}
