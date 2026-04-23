import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_globals.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/features/auth/login_screen.dart';
import 'package:grh_mobile/features/conges/conge_request_screen.dart';
import 'package:grh_mobile/features/dashboard/admin_console_screen.dart';
import 'package:grh_mobile/features/dashboard/direction_dashboard.dart';
import 'package:grh_mobile/features/dashboard/employee_workspace_screen.dart';
import 'package:grh_mobile/features/dashboard/rh_dashboard.dart';
import 'package:grh_mobile/features/employees/employee_detail_screen.dart';
import 'package:grh_mobile/features/employees/employee_list_screen.dart';
import 'package:grh_mobile/features/paie/paie_calculation_screen.dart';
import 'package:grh_mobile/features/presences/presence_overview_screen.dart';
import 'package:grh_mobile/features/rapports/reports_hub_screen.dart';
import 'package:grh_mobile/shared/models/employe.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authNotifierProvider);

  bool canAccess(String location, UserRole role) {
    switch (role) {
      case UserRole.admin:
        return location.startsWith('/admin');
      case UserRole.rhManager:
        return location.startsWith('/rh');
      case UserRole.employee:
        return location.startsWith('/employee');
      case UserRole.direction:
        return location.startsWith('/direction') || location == AppRoutes.rapports;
    }
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: auth,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == AppRoutes.login;
      if (!auth.isInitialized) {
        return null;
      }
      if (!auth.isAuthenticated) {
        return loggingIn ? null : AppRoutes.login;
      }
      final role = auth.role!;
      final home = defaultRouteForRole(role);
      if (loggingIn) {
        return home;
      }
      if (!canAccess(state.uri.path, role)) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.rhDashboard,
        builder: (context, state) => const RhDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.employees,
        builder: (context, state) => const EmployeeListScreen(),
      ),
      GoRoute(
        path: AppRoutes.presences,
        builder: (context, state) => const PresenceOverviewScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.employees}/:matricule',
        builder: (context, state) => EmployeeDetailScreen(
          matricule: state.pathParameters['matricule']!,
          employee: state.extra is Employe ? state.extra as Employe : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.conges,
        builder: (context, state) => const CongeRequestScreen(),
      ),
      GoRoute(
        path: AppRoutes.paie,
        builder: (context, state) => const PaieCalculationScreen(),
      ),
      GoRoute(
        path: AppRoutes.directionDashboard,
        builder: (context, state) => const DirectionDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.employeeHome,
        builder: (context, state) => const EmployeeWorkspaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminConsoleScreen(sectionTitle: 'Dashboard'),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => const AdminConsoleScreen(sectionTitle: 'Utilisateurs'),
      ),
      GoRoute(
        path: AppRoutes.adminRoles,
        builder: (context, state) => const AdminConsoleScreen(sectionTitle: 'Rôles'),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (context, state) => const AdminConsoleScreen(sectionTitle: 'Paramètres'),
      ),
      GoRoute(
        path: AppRoutes.rapports,
        builder: (context, state) => const ReportsHubScreen(),
      ),
    ],
  );
});
