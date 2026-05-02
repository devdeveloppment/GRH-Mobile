package com.grhmobile.dto.dashboard;

import java.time.LocalDate;

public record BirthdayDto(
    Long employeeId,
    String employeeName,
    String avatarUrl,
    LocalDate birthDate,
    int daysUntilBirthday
) {
}
