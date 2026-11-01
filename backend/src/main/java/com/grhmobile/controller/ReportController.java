package com.grhmobile.controller;

import com.grhmobile.dto.report.GenerateReportRequest;
import com.grhmobile.dto.report.ReportExport;
import com.grhmobile.service.ReportService;

import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/export")
    @PreAuthorize("@acl.can('VIEW_REPORTS')")
    public ResponseEntity<byte[]> export(@RequestParam(defaultValue = "pdf") String format) {
        ReportExport export = reportService.export(format);
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename(export.fileName()).build().toString())
            .contentType(MediaType.parseMediaType(export.contentType()))
            .body(export.content());
    }

    @PreAuthorize("@acl.can('VIEW_REPORTS')")
    @PostMapping("/generate")
    public ResponseEntity<byte[]> generate(@RequestBody GenerateReportRequest request) {
        ReportExport export = reportService.generateReport(request);
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION,
                ContentDisposition.attachment().filename(export.fileName()).build().toString())
            .contentType(MediaType.parseMediaType(export.contentType()))
            .body(export.content());
    }
}
