import 'package:flutter/material.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';

class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String rhDashboard = '/rh/dashboard';
  static const String employeeHome = '/employee/home';
  static const String directionDashboard = '/direction/dashboard';
  static const String employees = '/rh/employees';
  static const String presences = '/rh/presences';
  static const String employeeDetail = '/rh/employees/detail';
  static const String conges = '/rh/conges';
  static const String paie = '/rh/paie';
  static const String rapports = '/rh/rapports';
  static const String departments = '/rh/departments';
  static const String adminUsers = '/admin/users';
  static const String adminRoles = '/admin/roles';
  static const String adminSettings = '/admin/settings';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
}

class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

List<NavigationItem> navigationItemsForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return const [
        NavigationItem(label: 'Dashboard',       route: AppRoutes.adminDashboard, icon: Icons.space_dashboard_outlined),
        NavigationItem(label: 'Employés',         route: AppRoutes.employees,      icon: Icons.people_alt_outlined),
        NavigationItem(label: 'Départements',     route: AppRoutes.departments,    icon: Icons.account_tree_outlined),
        NavigationItem(label: 'Présences',        route: AppRoutes.presences,      icon: Icons.fact_check_outlined),
        NavigationItem(label: 'Congés',           route: AppRoutes.conges,         icon: Icons.event_available_outlined),
        NavigationItem(label: 'Paie',             route: AppRoutes.paie,           icon: Icons.receipt_long_outlined),
        NavigationItem(label: 'Rapports',         route: AppRoutes.rapports,       icon: Icons.bar_chart_outlined),
        NavigationItem(label: 'Utilisateurs',     route: AppRoutes.adminUsers,     icon: Icons.group_outlined),
        NavigationItem(label: 'Notifications',    route: AppRoutes.notifications,  icon: Icons.notifications_outlined),
        NavigationItem(label: 'Paramètres',       route: AppRoutes.adminSettings,  icon: Icons.settings_outlined),
      ];
    case UserRole.rhManager:
      return const [
        NavigationItem(label: 'Dashboard',    route: AppRoutes.rhDashboard,   icon: Icons.space_dashboard_outlined),
        NavigationItem(label: 'Employés',     route: AppRoutes.employees,     icon: Icons.people_alt_outlined),
        NavigationItem(label: 'Présences',    route: AppRoutes.presences,     icon: Icons.fact_check_outlined),
        NavigationItem(label: 'Congés',       route: AppRoutes.conges,        icon: Icons.event_available_outlined),
        NavigationItem(label: 'Paie',         route: AppRoutes.paie,          icon: Icons.receipt_long_outlined),
        NavigationItem(label: 'Rapports',     route: AppRoutes.rapports,      icon: Icons.bar_chart_outlined),
        NavigationItem(label: 'Notifications',route: AppRoutes.notifications, icon: Icons.notifications_outlined),
      ];
    case UserRole.employee:
      return const [
        NavigationItem(label: 'Profil',        route: AppRoutes.employeeHome,  icon: Icons.badge_outlined),
        NavigationItem(label: 'Présences',     route: AppRoutes.employeeHome,  icon: Icons.access_time_outlined),
        NavigationItem(label: 'Congés',        route: AppRoutes.employeeHome,  icon: Icons.event_note_outlined),
        NavigationItem(label: 'Bulletin',      route: AppRoutes.employeeHome,  icon: Icons.description_outlined),
        NavigationItem(label: 'Notifications', route: AppRoutes.notifications, icon: Icons.notifications_outlined),
      ];
    case UserRole.direction:
      return const [
        NavigationItem(label: 'Dashboard',     route: AppRoutes.directionDashboard, icon: Icons.query_stats_outlined),
        NavigationItem(label: 'Rapports',      route: AppRoutes.rapports,           icon: Icons.insert_chart_outlined),
        NavigationItem(label: 'Indicateurs KPI',route: AppRoutes.directionDashboard,icon: Icons.track_changes_outlined),
        NavigationItem(label: 'Notifications', route: AppRoutes.notifications,      icon: Icons.notifications_outlined),
      ];
  }
}

String defaultRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return AppRoutes.adminDashboard;
    case UserRole.rhManager:
      return AppRoutes.rhDashboard;
    case UserRole.employee:
      return AppRoutes.employeeHome;
    case UserRole.direction:
      return AppRoutes.directionDashboard;
  }
}
