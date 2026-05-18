package com.grhmobile.controller;

import com.grhmobile.dto.audit.AuditLogResponse;
import com.grhmobile.dto.common.PagedResponse;
import com.grhmobile.service.AuditLogService;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;

@RestController
@RequestMapping("/api/audit-logs")
@PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN','HR_ADMIN')")
public class AuditLogController {

    private final AuditLogService auditLogService;

    public AuditLogController(AuditLogService auditLogService) {
        this.auditLogService = auditLogService;
    }

    @GetMapping
    public PagedResponse<AuditLogResponse> search(
        @RequestParam(required = false) String entite,
        @RequestParam(required = false) String action,
        @RequestParam(required = false) Long acteurId,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime debut,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime fin,
        @RequestParam(defaultValue = "1")  int page,
        @RequestParam(defaultValue = "20") int limit
    ) {
        return auditLogService.search(entite, action, acteurId, debut, fin, page, limit);
    }
}
