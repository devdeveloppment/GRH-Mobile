package com.grhmobile.dto.dashboard;

import java.util.List;

public record DashboardSummaryResponse(
    long totalEmployees,
    long presentToday,
    long pendingLeaves,
    long payslipsThisMonth,
    double payrollMass,
    double attendanceRate,
    long approvedLeaves,
    double turnoverRate,
    List<DashboardPointDto> weeklyAttendance,
    List<DashboardPointDto> payrollEvolution,
    List<DashboardPointDto> departmentBreakdown,
    List<RecentActivityDto> recentActivities
) {
}
