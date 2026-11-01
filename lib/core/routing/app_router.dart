import 'package:grh_mobile/features/profile/change_password_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_globals.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/features/admin/admin_roles_screen.dart';
import 'package:grh_mobile/features/admin/admin_settings_screen.dart';
import 'package:grh_mobile/features/admin/admin_users_screen.dart';
import 'package:grh_mobile/features/auth/login_screen.dart';
import 'package:grh_mobile/features/conges/conge_request_screen.dart';
import 'package:grh_mobile/features/dashboard/admin_console_screen.dart';
import 'package:grh_mobile/features/dashboard/direction_dashboard.dart';
import 'package:grh_mobile/features/dashboard/employee_workspace_screen.dart';
import 'package:grh_mobile/features/dashboard/rh_dashboard_modern.dart';
import 'package:grh_mobile/features/assistant/assistant_screen.dart';
import 'package:grh_mobile/features/frais/notes_frais_screen.dart';
import 'package:grh_mobile/features/parametrage/parametrage_rh_screen.dart';
import 'package:grh_mobile/features/employees/employee_detail_screen.dart';
import 'package:grh_mobile/features/employees/employee_list_screen.dart';
import 'package:grh_mobile/features/notifications/notifications_screen.dart';
import 'package:grh_mobile/features/paie/paie_calculation_screen.dart';
import 'package:grh_mobile/features/presences/presence_overview_screen.dart';
import 'package:grh_mobile/features/profile/profile_screen.dart';
import 'package:grh_mobile/features/qr/employee_qr_screen.dart';
import 'package:grh_mobile/features/qr/qr_scanner_screen.dart';
import 'package:grh_mobile/features/rapports/reports_hub_screen.dart';
import 'package:grh_mobile/features/departments/department_list_screen.dart';
import 'package:grh_mobile/features/postes/poste_list_screen.dart';
import 'package:grh_mobile/features/contrats/contrats_screen.dart';
import 'package:grh_mobile/features/recrutement/recrutement_screen.dart';
import 'package:grh_mobile/features/formations/formations_screen.dart';
import 'package:grh_mobile/features/evaluations/evaluations_screen.dart';
import 'package:grh_mobile/features/audit/audit_log_screen.dart';
import 'package:grh_mobile/features/dashboard/manager_dashboard_screen.dart';
import 'package:grh_mobile/features/recrutement/candidatures_screen.dart';
import 'package:grh_mobile/features/recrutement/postuler_screen.dart';
import 'package:grh_mobile/shared/models/employe.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authNotifierProvider);

  bool canAccess(String location, UserRole role) {
    // Super admin et admin accèdent à tout
    if (role.isAdmin) return true;

    switch (role) {
      case UserRole.hrAdmin:
      case UserRole.rhManager:
        return location.startsWith('/rh') ||
            location == AppRoutes.notesFrais ||
            location == AppRoutes.notifications ||
            location == AppRoutes.qrScanner ||
            location == AppRoutes.profile;
      case UserRole.payrollOfficer:
        return location == AppRoutes.paie ||
            location == AppRoutes.contrats ||
            location == AppRoutes.notesFrais ||
            location == AppRoutes.rapports ||
            location == AppRoutes.notifications ||
            location == AppRoutes.profile;
      case UserRole.manager:
        return location.startsWith('/manager') ||
            location.startsWith('${AppRoutes.employees}/') ||
            location == AppRoutes.qrScanner ||
            location == AppRoutes.presences ||
            location == AppRoutes.conges ||
            location == AppRoutes.evaluations ||
            location == AppRoutes.formations ||
            location == AppRoutes.notifications ||
            location == AppRoutes.profile;
      case UserRole.recruiter:
        return location.startsWith(AppRoutes.recrutement) ||
            location == AppRoutes.notifications ||
            location == AppRoutes.profile;
      case UserRole.trainer:
        return location == AppRoutes.formations ||
            location == AppRoutes.notifications ||
            location == AppRoutes.profile;
      case UserRole.employee:
        return location.startsWith('/employee') ||
            location == AppRoutes.notesFrais ||
            location == AppRoutes.notifications ||
            location == AppRoutes.employeeQr ||
            location == AppRoutes.profile;
      case UserRole.direction:
        return location.startsWith('/direction') ||
            location == AppRoutes.rapports ||
            location == AppRoutes.evaluations ||
            location == AppRoutes.notifications ||
            location == AppRoutes.profile;
      default:
        return false;
    }
  }

  /// Accès par rôle, complété par les permissions accordées depuis l'écran « Rôles ».
  bool isAllowed(String location, Utilisateur user) {
    if (location == AppRoutes.changePassword) return true;
    // Assistant : ouvert à tous ; les droits sont vérifiés par outil côté serveur.
    if (location == AppRoutes.assistant) return true;
    if (canAccess(location, user.role)) return true;
    if (user.hasPermission('MANAGE_EMPLOYEES') && location.startsWith(AppRoutes.employees)) return true;
    if (user.hasPermission('MANAGE_PAIE') && location == AppRoutes.paie) return true;
    if (user.hasPermission('VIEW_REPORTS') && location == AppRoutes.rapports) return true;
    if (user.hasPermission('MANAGE_LEAVES') && location == AppRoutes.conges) return true;
    if (user.hasPermission('MANAGE_USERS') && location == AppRoutes.adminUsers) return true;
    return false;
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: auth,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == AppRoutes.login;
      // Route publique de candidature — pas d'auth requise
      if (state.uri.path.startsWith(AppRoutes.postuler)) return null;
      if (!auth.isInitialized) return null;
      if (!auth.isAuthenticated) return loggingIn ? null : AppRoutes.login;

      final role = auth.role!;
      // Mot de passe temporaire : changement obligatoire avant toute autre action
      if (auth.mustChangePassword) {
        return state.uri.path == AppRoutes.changePassword ? null : AppRoutes.changePassword;
      }
      final home = defaultRouteForRole(role);
      if (loggingIn) return home;
      if (!isAllowed(state.uri.path, auth.user!)) return home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login,
          builder: (_, __) => const LoginScreen()),

      // ─── RH / Admin ────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.rhDashboard,
          builder: (_, __) => const RhDashboardModernScreen()),
      GoRoute(path: AppRoutes.employees,
          builder: (_, __) => const EmployeeListScreen()),
      GoRoute(path: '${AppRoutes.employees}/:matricule',
          builder: (_, state) => EmployeeDetailScreen(
            matricule: state.pathParameters['matricule']!,
            employee: state.extra is Employe ? state.extra as Employe : null,
          )),
      GoRoute(path: AppRoutes.presences,
          builder: (_, __) => const PresenceOverviewScreen()),
      GoRoute(path: AppRoutes.conges,
          builder: (_, __) => const CongeRequestScreen()),
      GoRoute(path: AppRoutes.paie,
          builder: (_, __) => const PaieCalculationScreen()),
      GoRoute(path: AppRoutes.rapports,
          builder: (_, __) => const ReportsHubScreen()),

      // Nouveaux modules RH
      GoRoute(path: AppRoutes.departements,
          builder: (_, __) => const DepartementListScreen()),
      GoRoute(path: AppRoutes.postes,
          builder: (_, __) => const PosteListScreen()),
      GoRoute(path: AppRoutes.contrats,
          builder: (_, __) => const ContratsScreen()),
      GoRoute(path: AppRoutes.recrutement,
          builder: (_, __) => const RecrutementScreen()),
      GoRoute(
        path: '${AppRoutes.recrutementCandidatures}/:offreId',
        builder: (_, state) {
          final offreId = int.parse(state.pathParameters['offreId']!);
          final extra = state.extra as Map<String, dynamic>?;
          return CandidaturesScreen(
            offreId: offreId,
            offreTitre: extra?['titre'] as String? ?? 'Offre #$offreId',
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.postuler}/:offreId',
        builder: (_, state) {
          final offreId = state.pathParameters['offreId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return PostulerScreen(
            offreId: offreId,
            offreTitre: extra?['titre'] as String?,
          );
        },
      ),
      GoRoute(path: AppRoutes.formations,
          builder: (_, __) => const FormationsScreen()),
      GoRoute(path: AppRoutes.evaluations,
          builder: (_, __) => const EvaluationsScreen()),
      GoRoute(path: AppRoutes.parametrageRh,
          builder: (_, __) => const ParametrageRhScreen()),
      GoRoute(path: AppRoutes.notesFrais,
          builder: (_, __) => const NotesFraisScreen()),
      GoRoute(path: AppRoutes.assistant,
          builder: (_, __) => const AssistantScreen()),

      // ─── Admin ─────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.adminDashboard,
          builder: (_, __) => const AdminConsoleScreen(sectionTitle: 'Dashboard')),
      GoRoute(path: AppRoutes.adminUsers,
          builder: (_, __) => const AdminUsersManagementScreen()),
      GoRoute(path: AppRoutes.adminRoles,
          builder: (_, __) => const AdminRolesScreen()),
      GoRoute(path: AppRoutes.adminSettings,
          builder: (_, __) => const AdminSettingsScreen()),
      GoRoute(path: AppRoutes.auditLog,
          builder: (_, __) => const AuditLogScreen()),

      // ─── Manager ───────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.managerDashboard,
          builder: (_, __) => const ManagerDashboardScreen()),

      // ─── Direction ─────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.directionDashboard,
          builder: (_, __) => const DirectionDashboardScreen()),

      // ─── Employee ──────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.employeeHome,
          builder: (_, __) => const EmployeeWorkspaceScreen()),
      GoRoute(path: AppRoutes.employeeQr,
          builder: (_, __) => const EmployeeQrScreen()),

      // ─── Commun ────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.notifications,
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.profile,
          builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRoutes.changePassword,
          builder: (_, __) => const ChangePasswordScreen()),
      GoRoute(path: AppRoutes.qrScanner,
          builder: (_, __) => const QrScannerScreen()),
    ],
  );
});
