class ChartPoint {
  final String label;
  final double value;

  ChartPoint({
    required this.label,
    required this.value,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'value': value,
  };
}

class LeaveRequest {
  final int id;
  final String employeeName;
  final String? avatarUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;

  LeaveRequest({
    required this.id,
    required this.employeeName,
    this.avatarUrl,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int? ?? 0,
      employeeName: json['employeeName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      startDate: DateTime.parse(json['startDate'] as String? ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] as String? ?? DateTime.now().toIso8601String()),
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeName': employeeName,
    'avatarUrl': avatarUrl,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };
}

class Birthday {
  final int employeeId;
  final String employeeName;
  final String? avatarUrl;
  final DateTime birthDate;
  final int daysUntilBirthday;

  Birthday({
    required this.employeeId,
    required this.employeeName,
    this.avatarUrl,
    required this.birthDate,
    required this.daysUntilBirthday,
  });

  factory Birthday.fromJson(Map<String, dynamic> json) {
    return Birthday(
      employeeId: json['employeeId'] as int? ?? 0,
      employeeName: json['employeeName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      birthDate: DateTime.parse(json['birthDate'] as String? ?? DateTime.now().toIso8601String()),
      daysUntilBirthday: json['daysUntilBirthday'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'employeeName': employeeName,
    'avatarUrl': avatarUrl,
    'birthDate': birthDate.toIso8601String(),
    'daysUntilBirthday': daysUntilBirthday,
  };
}

class QuickStats {
  final int activeContracts;
  final int probationaryPeriod;
  final int departures;
  final int trainingInProgress;
  final int cdiCount;
  final int cddCount;
  final int internshipCount;

  QuickStats({
    required this.activeContracts,
    required this.probationaryPeriod,
    required this.departures,
    required this.trainingInProgress,
    required this.cdiCount,
    required this.cddCount,
    required this.internshipCount,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      activeContracts: json['activeContracts'] as int? ?? 0,
      probationaryPeriod: json['probationaryPeriod'] as int? ?? 0,
      departures: json['departures'] as int? ?? 0,
      trainingInProgress: json['trainingInProgress'] as int? ?? 0,
      cdiCount: json['cdiCount'] as int? ?? 0,
      cddCount: json['cddCount'] as int? ?? 0,
      internshipCount: json['internshipCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'activeContracts': activeContracts,
    'probationaryPeriod': probationaryPeriod,
    'departures': departures,
    'trainingInProgress': trainingInProgress,
    'cdiCount': cdiCount,
    'cddCount': cddCount,
    'internshipCount': internshipCount,
  };
}

class EnhancedDashboard {
  final int totalEmployees;
  final double attendanceRate;
  final int pendingLeaves;
  final double payrollMass;
  final List<ChartPoint> attendanceEvolution;
  final List<ChartPoint> departmentBreakdown;
  final List<LeaveRequest> recentLeaveRequests;
  final List<Birthday> upcomingBirthdays;
  final QuickStats quickStats;
  final List<ChartPoint> payrollBreakdown;

  EnhancedDashboard({
    required this.totalEmployees,
    required this.attendanceRate,
    required this.pendingLeaves,
    required this.payrollMass,
    required this.attendanceEvolution,
    required this.departmentBreakdown,
    required this.recentLeaveRequests,
    required this.upcomingBirthdays,
    required this.quickStats,
    required this.payrollBreakdown,
  });

  factory EnhancedDashboard.fromJson(Map<String, dynamic> json) {
    return EnhancedDashboard(
      totalEmployees: json['totalEmployees'] as int? ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0,
      pendingLeaves: json['pendingLeaves'] as int? ?? 0,
      payrollMass: (json['payrollMass'] as num?)?.toDouble() ?? 0,
      attendanceEvolution: (json['attendanceEvolution'] as List?)
          ?.map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      departmentBreakdown: (json['departmentBreakdown'] as List?)
          ?.map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      recentLeaveRequests: (json['recentLeaveRequests'] as List?)
          ?.map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      upcomingBirthdays: (json['upcomingBirthdays'] as List?)
          ?.map((e) => Birthday.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      quickStats: QuickStats.fromJson((json['quickStats'] as Map<String, dynamic>?) ?? {}),
      payrollBreakdown: (json['payrollBreakdown'] as List?)
          ?.map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'totalEmployees': totalEmployees,
    'attendanceRate': attendanceRate,
    'pendingLeaves': pendingLeaves,
    'payrollMass': payrollMass,
    'attendanceEvolution': attendanceEvolution.map((e) => e.toJson()).toList(),
    'departmentBreakdown': departmentBreakdown.map((e) => e.toJson()).toList(),
    'recentLeaveRequests': recentLeaveRequests.map((e) => e.toJson()).toList(),
    'upcomingBirthdays': upcomingBirthdays.map((e) => e.toJson()).toList(),
    'quickStats': quickStats.toJson(),
    'payrollBreakdown': payrollBreakdown.map((e) => e.toJson()).toList(),
  };
}
