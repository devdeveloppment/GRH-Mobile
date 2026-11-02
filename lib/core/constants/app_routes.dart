import 'package:flutter/material.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';

class AppRoutes {
  const AppRoutes._();

  static const String login              = '/login';
  static const String adminDashboard     = '/admin/dashboard';
  static const String rhDashboard        = '/rh/dashboard';
  static const String employeeHome       = '/employee/home';
  static const String directionDashboard = '/direction/dashboard';
  static const String managerDashboard   = '/manager/dashboard';

  static const String employees          = '/rh/employees';
  static const String presences          = '/rh/presences';
  static const String conges             = '/rh/conges';
  static const String paie               = '/rh/paie';
  static const String rapports           = '/rh/rapports';

  // Nouveaux modules
  static const String departements       = '/rh/departements';
  static const String postes             = '/rh/postes';
  static const String contrats           = '/rh/contrats';
  static const String recrutement        = '/rh/recrutement';
  static const String formations         = '/rh/formations';
  static const String evaluations        = '/rh/evaluations';
  static const String auditLog           = '/admin/audit';
  static const String parametrageRh      = '/rh/parametrage';
  static const String notesFrais         = '/frais';
  static const String assistant          = '/assistant';
  static const String paieConfiguration  = '/rh/paie/configuration';
  static const String integration        = '/rh/integration';
  static const String plateforme         = '/plateforme/entreprises';

  static const String recrutementCandidatures = '/rh/recrutement/candidatures';
  static const String postuler            = '/apply';

  static const String adminUsers         = '/admin/users';
  static const String adminRoles         = '/admin/roles';
  static const String adminSettings      = '/admin/settings';
  static const String notifications      = '/notifications';
  static const String profile            = '/profile';
  static const String changePassword     = '/change-password';
  static const String qrScanner         = '/qr/scanner';
  static const String employeeQr        = '/employee/qr';
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
    case UserRole.superAdmin:
      return const [
        NavigationItem(label: 'Entreprises',  route: AppRoutes.plateforme,      icon: Icons.domain_outlined),
        ..._adminItems,
      ];
    case UserRole.admin:
      return _adminItems;

    case UserRole.hrAdmin:
    case UserRole.rhManager:
      return const [
        NavigationItem(label: 'Dashboard',    route: AppRoutes.rhDashboard,     icon: Icons.space_dashboard_outlined),
        NavigationItem(label: 'Employés',     route: AppRoutes.employees,       icon: Icons.people_alt_outlined),
        NavigationItem(label: 'Arrivées / départs', route: AppRoutes.integration, icon: Icons.how_to_reg_outlined),
        NavigationItem(label: 'Départements', route: AppRoutes.departements,    icon: Icons.account_tree_outlined),
        NavigationItem(label: 'Postes',       route: AppRoutes.postes,          icon: Icons.work_outline),
        NavigationItem(label: 'Présences',    route: AppRoutes.presences,       icon: Icons.fact_check_outlined),
        NavigationItem(label: 'Congés',       route: AppRoutes.conges,          icon: Icons.event_available_outlined),
        NavigationItem(label: 'Recrutement',  route: AppRoutes.recrutement,     icon: Icons.person_add_outlined),
        NavigationItem(label: 'Formations',   route: AppRoutes.formations,      icon: Icons.school_outlined),
        NavigationItem(label: 'Évaluations',  route: AppRoutes.evaluations,     icon: Icons.star_outline),
        NavigationItem(label: 'Contrats',     route: AppRoutes.contrats,        icon: Icons.description_outlined),
        NavigationItem(label: 'Paie',         route: AppRoutes.paie,            icon: Icons.receipt_long_outlined),
        NavigationItem(label: 'Config. paie', route: AppRoutes.paieConfiguration, icon: Icons.rule_outlined),
        NavigationItem(label: 'Notes de frais', route: AppRoutes.notesFrais,    icon: Icons.receipt_outlined),
        NavigationItem(label: 'Paramétrage RH', route: AppRoutes.parametrageRh, icon: Icons.tune_outlined),
        NavigationItem(label: 'Rapports',     route: AppRoutes.rapports,        icon: Icons.bar_chart_outlined),
        NavigationItem(label: 'Assistant RH', route: AppRoutes.assistant,       icon: Icons.smart_toy_outlined),
        NavigationItem(label: 'Notifications',route: AppRoutes.notifications,   icon: Icons.notifications_outlined),
      ];

    case UserRole.payrollOfficer:
      return const [
        NavigationItem(label: 'Paie',         route: AppRoutes.paie,            icon: Icons.receipt_long_outlined),
        NavigationItem(label: 'Config. paie', route: AppRoutes.paieConfiguration, icon: Icons.rule_outlined),
        NavigationItem(label: 'Contrats',     route: AppRoutes.contrats,        icon: Icons.description_outlined),
        NavigationItem(label: 'Notes de frais', route: AppRoutes.notesFrais,    icon: Icons.receipt_outlined),
        NavigationItem(label: 'Rapports',     route: AppRoutes.rapports,        icon: Icons.bar_chart_outlined),
        NavigationItem(label: 'Assistant RH', route: AppRoutes.assistant,       icon: Icons.smart_toy_outlined),
        NavigationItem(label: 'Notifications',route: AppRoutes.notifications,   icon: Icons.notifications_outlined),
      ];
    case UserRole.manager:
      return const [
        NavigationItem(label: 'Mon équipe',   route: AppRoutes.managerDashboard,icon: Icons.group_outlined),
        NavigationItem(label: 'Présences',    route: AppRoutes.presences,       icon: Icons.fact_check_outlined),
        NavigationItem(label: 'Congés',       route: AppRoutes.conges,          icon: Icons.event_available_outlined),
        NavigationItem(label: 'Évaluations',  route: AppRoutes.evaluations,     icon: Icons.star_outline),
        NavigationItem(label: 'Formations',   route: AppRoutes.formations,      icon: Icons.school_outlined),
        NavigationItem(label: 'Assistant RH', route: AppRoutes.assistant,       icon: Icons.smart_toy_outlined),
        NavigationItem(label: 'Notifications',route: AppRoutes.notifications,   icon: Icons.notifications_outlined),
      ];

    case UserRole.recruiter:
      return const [
        NavigationItem(label: 'Recrutement',  route: AppRoutes.recrutement,     icon: Icons.person_add_outlined),
        NavigationItem(label: 'Assistant RH', route: AppRoutes.assistant,       icon: Icons.smart_toy_outlined),
        NavigationItem(label: 'Notifications',route: AppRoutes.notifications,   icon: Icons.notifications_outlined),
      ];

    case UserRole.trainer:
      return const [
        NavigationItem(label: 'Formations',   route: AppRoutes.formations,      icon: Icons.school_outlined),
        NavigationItem(label: 'Assistant RH', route: AppRoutes.assistant,       icon: Icons.smart_toy_outlined),
        NavigationItem(label: 'Notifications',route: AppRoutes.notifications,   icon: Icons.notifications_outlined),
      ];

    case UserRole.employee:
      return const [
        NavigationItem(label: 'Profil',       route: AppRoutes.employeeHome,    icon: Icons.badge_outlined),
        NavigationItem(label: 'Présences',    route: AppRoutes.employeeHome,    icon: Icons.access_time_outlined),
        NavigationItem(label: 'Congés',       route: AppRoutes.employeeHome,    icon: Icons.event_note_outlined),
        NavigationItem(label: 'Bulletin',     route: AppRoutes.employeeHome,    icon: Icons.description_outlined),
        NavigationItem(label: 'Notes de frais', route: AppRoutes.notesFrais,    icon: Icons.receipt_outlined),
        NavigationItem(label: 'Assistant RH', route: AppRoutes.assistant,       icon: Icons.smart_toy_outlined),
        NavigationItem(label: 'Notifications',route: AppRoutes.notifications,   icon: Icons.notifications_outlined),
      ];

    case UserRole.direction:
      return const [
        NavigationItem(label: 'Dashboard',     route: AppRoutes.directionDashboard, icon: Icons.query_stats_outlined),
        NavigationItem(label: 'Rapports',      route: AppRoutes.rapports,           icon: Icons.insert_chart_outlined),
        NavigationItem(label: 'Évaluations',   route: AppRoutes.evaluations,        icon: Icons.star_outline),
        NavigationItem(label: 'Assistant RH', route: AppRoutes.assistant,       icon: Icons.smart_toy_outlined),
        NavigationItem(label: 'Notifications', route: AppRoutes.notifications,      icon: Icons.notifications_outlined),
      ];
  }
}

const List<NavigationItem> _adminItems = [
  NavigationItem(label: 'Dashboard',    route: AppRoutes.adminDashboard,  icon: Icons.space_dashboard_outlined),
  NavigationItem(label: 'Employés',     route: AppRoutes.employees,       icon: Icons.people_alt_outlined),
  NavigationItem(label: 'Arrivées / départs', route: AppRoutes.integration, icon: Icons.how_to_reg_outlined),
  NavigationItem(label: 'Départements', route: AppRoutes.departements,    icon: Icons.account_tree_outlined),
  NavigationItem(label: 'Postes',       route: AppRoutes.postes,          icon: Icons.work_outline),
  NavigationItem(label: 'Présences',    route: AppRoutes.presences,       icon: Icons.fact_check_outlined),
  NavigationItem(label: 'Congés',       route: AppRoutes.conges,          icon: Icons.event_available_outlined),
  NavigationItem(label: 'Paie',         route: AppRoutes.paie,            icon: Icons.receipt_long_outlined),
  NavigationItem(label: 'Config. paie', route: AppRoutes.paieConfiguration, icon: Icons.rule_outlined),
  NavigationItem(label: 'Recrutement',  route: AppRoutes.recrutement,     icon: Icons.person_add_outlined),
  NavigationItem(label: 'Formations',   route: AppRoutes.formations,      icon: Icons.school_outlined),
  NavigationItem(label: 'Évaluations',  route: AppRoutes.evaluations,     icon: Icons.star_outline),
  NavigationItem(label: 'Rapports',     route: AppRoutes.rapports,        icon: Icons.bar_chart_outlined),
  NavigationItem(label: 'Utilisateurs', route: AppRoutes.adminUsers,      icon: Icons.group_outlined),
  NavigationItem(label: 'Notes de frais', route: AppRoutes.notesFrais,    icon: Icons.receipt_outlined),
  NavigationItem(label: 'Paramétrage RH', route: AppRoutes.parametrageRh, icon: Icons.tune_outlined),
  NavigationItem(label: 'Audit',        route: AppRoutes.auditLog,        icon: Icons.history_outlined),
  NavigationItem(label: 'Assistant RH', route: AppRoutes.assistant,       icon: Icons.smart_toy_outlined),
  NavigationItem(label: 'Notifications',route: AppRoutes.notifications,   icon: Icons.notifications_outlined),
  NavigationItem(label: 'Paramètres',   route: AppRoutes.adminSettings,   icon: Icons.settings_outlined),
];

String defaultRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
    case UserRole.admin:
      return AppRoutes.adminDashboard;
    case UserRole.hrAdmin:
    case UserRole.rhManager:
      return AppRoutes.rhDashboard;
    case UserRole.payrollOfficer:
      return AppRoutes.paie;
    case UserRole.manager:
      return AppRoutes.managerDashboard;
    case UserRole.recruiter:
      return AppRoutes.recrutement;
    case UserRole.trainer:
      return AppRoutes.formations;
    case UserRole.employee:
      return AppRoutes.employeeHome;
    case UserRole.direction:
      return AppRoutes.directionDashboard;
  }
}
