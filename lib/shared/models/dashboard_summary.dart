class DashboardPoint {
  const DashboardPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  factory DashboardPoint.fromJson(Map<String, dynamic> json) {
    return DashboardPoint(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
      };
}

class RecentActivity {
  const RecentActivity({
    required this.id,
    required this.employeeName,
    required this.action,
    required this.timestamp,
    this.avatarUrl,
  });

  final String id;
  final String employeeName;
  final String action;
  final DateTime timestamp;
  final String? avatarUrl;

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id']?.toString() ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      action: json['action'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeName': employeeName,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
        'avatarUrl': avatarUrl,
      };
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalEmployees,
    required this.presentToday,
    required this.pendingLeaves,
    required this.payslipsThisMonth,
    required this.payrollMass,
    required this.attendanceRate,
    required this.approvedLeaves,
    required this.turnoverRate,
    required this.weeklyAttendance,
    required this.payrollEvolution,
    required this.departmentBreakdown,
    required this.recentActivities,
  });

  final int totalEmployees;
  final int presentToday;
  final int pendingLeaves;
  final int payslipsThisMonth;
  final double payrollMass;
  final double attendanceRate;
  final int approvedLeaves;
  final double turnoverRate;
  final List<DashboardPoint> weeklyAttendance;
  final List<DashboardPoint> payrollEvolution;
  final List<DashboardPoint> departmentBreakdown;
  final List<RecentActivity> recentActivities;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    List<DashboardPoint> parsePoints(String key) {
      final raw = json[key] as List<dynamic>? ?? <dynamic>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(DashboardPoint.fromJson)
          .toList(growable: false);
    }

    final rawActivities = json['recentActivities'] as List<dynamic>? ?? <dynamic>[];

    return DashboardSummary(
      totalEmployees: (json['totalEmployees'] as num?)?.toInt() ?? 0,
      presentToday: (json['presentToday'] as num?)?.toInt() ?? 0,
      pendingLeaves: (json['pendingLeaves'] as num?)?.toInt() ?? 0,
      payslipsThisMonth: (json['payslipsThisMonth'] as num?)?.toInt() ?? 0,
      payrollMass: (json['payrollMass'] as num?)?.toDouble() ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0,
      approvedLeaves: (json['approvedLeaves'] as num?)?.toInt() ?? 0,
      turnoverRate: (json['turnoverRate'] as num?)?.toDouble() ?? 0,
      weeklyAttendance: parsePoints('weeklyAttendance'),
      payrollEvolution: parsePoints('payrollEvolution'),
      departmentBreakdown: parsePoints('departmentBreakdown'),
      recentActivities: rawActivities
          .whereType<Map<String, dynamic>>()
          .map(RecentActivity.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalEmployees': totalEmployees,
        'presentToday': presentToday,
        'pendingLeaves': pendingLeaves,
        'payslipsThisMonth': payslipsThisMonth,
        'payrollMass': payrollMass,
        'attendanceRate': attendanceRate,
        'approvedLeaves': approvedLeaves,
        'turnoverRate': turnoverRate,
        'weeklyAttendance': weeklyAttendance.map((item) => item.toJson()).toList(),
        'payrollEvolution': payrollEvolution.map((item) => item.toJson()).toList(),
        'departmentBreakdown': departmentBreakdown.map((item) => item.toJson()).toList(),
        'recentActivities': recentActivities.map((item) => item.toJson()).toList(),
      };
}
