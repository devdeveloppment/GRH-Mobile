package com.grhmobile.dto.dashboard;

import java.time.OffsetDateTime;

public record RecentActivityDto(
    String id,
    String employeeName,
    String action,
    OffsetDateTime timestamp,
    String avatarUrl
) {
}
