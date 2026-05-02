package com.grhmobile.dto.dashboard;

import java.time.LocalDate;
import java.time.OffsetDateTime;

public record LeaveRequestDto(
    Long id,
    String employeeName,
    String avatarUrl,
    LocalDate startDate,
    LocalDate endDate,
    String status,
    OffsetDateTime createdAt
) {
}
