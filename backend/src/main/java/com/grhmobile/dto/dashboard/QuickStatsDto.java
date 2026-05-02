package com.grhmobile.dto.dashboard;

public record QuickStatsDto(
    long activeContracts,
    long probationaryPeriod,
    long departures,
    long trainingInProgress,
    long cdiCount,
    long cddCount,
    long internshipCount
) {
}
