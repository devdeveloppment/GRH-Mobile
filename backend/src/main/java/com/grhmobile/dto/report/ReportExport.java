package com.grhmobile.dto.report;

public record ReportExport(
    byte[] content,
    String fileName,
    String contentType
) {
}
