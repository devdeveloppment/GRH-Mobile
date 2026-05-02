package com.grhmobile.dto.dashboard;

import java.util.List;

public record EnhancedDashboardResponse(
    // KPI Summary
    long totalEmployees,
    double attendanceRate,
    long pendingLeaves,
    double payrollMass,
    
    // Charts data
    List<DashboardPointDto> attendanceEvolution,
    List<DashboardPointDto> departmentBreakdown,
    
    // Lists
    List<LeaveRequestDto> recentLeaveRequests,
    List<BirthdayDto> upcomingBirthdays,
    
    // Stats
    QuickStatsDto quickStats,
    
    // Payroll summary
    List<DashboardPointDto> payrollBreakdown
) {
}
