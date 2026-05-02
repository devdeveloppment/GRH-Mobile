package com.grhmobile.controller;

import com.grhmobile.dto.dashboard.DashboardSummaryResponse;
import com.grhmobile.dto.dashboard.EnhancedDashboardResponse;
import com.grhmobile.service.DashboardService;

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
    public DashboardSummaryResponse summary() {
        return dashboardService.getSummary();
    }

    @GetMapping("/enhanced")
    public EnhancedDashboardResponse enhanced() {
        return dashboardService.getEnhancedDashboard();
    }
}
