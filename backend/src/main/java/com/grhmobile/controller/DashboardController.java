package com.grhmobile.controller;

import com.grhmobile.dto.dashboard.DashboardSummaryResponse;
import com.grhmobile.dto.dashboard.EnhancedDashboardResponse;
import com.grhmobile.service.DashboardService;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/summary")
    @PreAuthorize("hasAnyRole('RH_MANAGER','PAYROLL_OFFICER','DIRECTION') or @acl.can('VIEW_REPORTS')")
    public DashboardSummaryResponse summary() {
        return dashboardService.getSummary();
    }

    @GetMapping("/enhanced")
    @PreAuthorize("hasAnyRole('RH_MANAGER','PAYROLL_OFFICER','DIRECTION') or @acl.can('VIEW_REPORTS')")
    public EnhancedDashboardResponse enhanced() {
        return dashboardService.getEnhancedDashboard();
    }
}
