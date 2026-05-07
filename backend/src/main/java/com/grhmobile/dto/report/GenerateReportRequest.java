package com.grhmobile.dto.report;

import java.time.LocalDate;

public record GenerateReportRequest(
    String type,
    LocalDate debut,
    LocalDate fin,
    String format,
    String service
) {}
