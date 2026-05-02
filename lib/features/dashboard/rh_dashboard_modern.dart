import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/dashboard_provider.dart';
import 'package:grh_mobile/shared/models/dashboard_models.dart';
import 'package:grh_mobile/shared/widgets/attendance_line_chart.dart';
import 'package:grh_mobile/shared/widgets/birthday_card.dart';
import 'package:grh_mobile/shared/widgets/dashboard_kpi_card.dart';
import 'package:grh_mobile/shared/widgets/department_donut_chart.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/leave_request_card.dart';
import 'package:grh_mobile/shared/widgets/quick_action_button.dart';

class RhDashboardModernScreen extends ConsumerWidget {
  const RhDashboardModernScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final dashboardAsync = ref.watch(enhancedDashboardProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1120;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.rhDashboard,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Bonjour, ${auth.user?.fullName ?? ""}',
            userName: 'Tableau de bord RH',
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
            actions: [
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Centre de notifications — GET /api/notifications'),
                    duration: Duration(seconds: 2),
                  ),
                ),
                icon: Badge(
                  backgroundColor: AppColors.accent,
                  label: const Text('3'),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.text2,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: EmployeeAvatar(
                  name: auth.user?.fullName ?? 'Utilisateur',
                  imageUrl: auth.user?.avatarUrl,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.rhDashboard, role: auth.role!),
          Expanded(
            child: dashboardAsync.when(
              data: (dashboard) => _buildDashboardContent(
                context,
                dashboard,
                isWide,
                onRefresh: () => ref.invalidate(enhancedDashboardProvider),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.text2),
                    const SizedBox(height: 12),
                    Text('Serveur indisponible', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(enhancedDashboardProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    EnhancedDashboard dashboard,
    bool isWide, {
    required VoidCallback onRefresh,
  }) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──────────────────────────────────────────
            Text(
              'Tableau de bord',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text1,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vue complète de vos indicateurs RH',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.text2,
                  ),
            ),
            const SizedBox(height: 20),

            // ── KPI Cards ──────────────────────────────────────────
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                DashboardKPICard(
                  icon: Icons.people_alt_outlined,
                  iconColor: Color(0xFF0E3D34),
                  title: 'Employés',
                  value: '${dashboard.totalEmployees}',
                  subtitle: '+ 12 ce mois',
                ),
                DashboardKPICard(
                  icon: Icons.check_circle_outline,
                  iconColor: Color(0xFF22C55E),
                  title: 'Taux de présence',
                  value: '${dashboard.attendanceRate.toStringAsFixed(0)}%',
                  subtitle: '+ 4% ce mois',
                ),
                DashboardKPICard(
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.accent,
                  title: 'Demandes de congés',
                  value: '${dashboard.pendingLeaves}',
                  subtitle: 'En attente',
                ),
                DashboardKPICard(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Color(0xFF10B981),
                  title: 'Masse salariale',
                  value: '${(dashboard.payrollMass / 1000000).toStringAsFixed(1)}M FCFA',
                  subtitle: 'Ce mois',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Quick Actions ──────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actions rapides',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.0,
                  children: [
                    QuickActionButton(
                      icon: Icons.person_add_outlined,
                      label: 'Ajouter un employé',
                      onTap: () => context.go(AppRoutes.employees),
                    ),
                    QuickActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Nouvelle demande de congé',
                      onTap: () => context.go(AppRoutes.conges),
                    ),
                    QuickActionButton(
                      icon: Icons.description_outlined,
                      label: 'Générer bulletin de paie',
                      onTap: () => context.go(AppRoutes.paie),
                    ),
                    QuickActionButton(
                      icon: Icons.assignment_outlined,
                      label: 'Voir les rapports',
                      onTap: () => context.go(AppRoutes.rapports),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Charts Row ──────────────────────────────────────────
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: AttendanceLineChart(
                      data: dashboard.attendanceEvolution,
                      title: 'Évolution des présences',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DepartmentDonutChart(
                      data: dashboard.departmentBreakdown,
                      title: 'Répartition par département',
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  AttendanceLineChart(
                    data: dashboard.attendanceEvolution,
                    title: 'Évolution des présences',
                  ),
                  const SizedBox(height: 16),
                  DepartmentDonutChart(
                    data: dashboard.departmentBreakdown,
                    title: 'Répartition par département',
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // ── Recent Leave Requests ──────────────────────────────────────────
            if (dashboard.recentLeaveRequests.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Demandes de congé récentes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.conges),
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: dashboard.recentLeaveRequests
                        .map((leave) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LeaveRequestCard(leave: leave),
                            ))
                        .toList(),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // ── Bottom Row (Birthdays & Stats) ──────────────────────────────────────────
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildBirthdaysSection(context, dashboard),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildQuickStatsSection(context, dashboard),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildBirthdaysSection(context, dashboard),
                  const SizedBox(height: 16),
                  _buildQuickStatsSection(context, dashboard),
                ],
              ),
            const SizedBox(height: 32),

            // ── Payroll Breakdown ──────────────────────────────────────────
            _buildPayrollSection(context, dashboard),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdaysSection(BuildContext context, EnhancedDashboard dashboard) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Anniversaires du mois',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.employees),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (dashboard.upcomingBirthdays.isNotEmpty)
            Column(
              children: dashboard.upcomingBirthdays
                  .map((birthday) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BirthdayCard(birthday: birthday),
                      ))
                  .toList(),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Aucun anniversaire ce mois'),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection(BuildContext context, EnhancedDashboard dashboard) {
    final stats = dashboard.quickStats;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques rapides',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          _buildStatRow('Contrats actifs', '${stats.activeContracts}'),
          _buildStatRow('Période d\'essai', '${stats.probationaryPeriod}'),
          _buildStatRow('Départs', '${stats.departures}'),
          _buildStatRow('Formations', '${stats.trainingInProgress}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text2,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollSection(BuildContext context, EnhancedDashboard dashboard) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition par type de contrat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          _buildContractBar('CDI', dashboard.quickStats.cdiCount, 0xFF0E3D34),
          const SizedBox(height: 16),
          _buildContractBar('CDD', dashboard.quickStats.cddCount, 0xFFFF6A1E),
          const SizedBox(height: 16),
          _buildContractBar('Stage', dashboard.quickStats.internshipCount, 0xFF3B82F6),
        ],
      ),
    );
  }

  Widget _buildContractBar(String label, int count, int color) {
    final maxCount = 50.0;
    final percentage = ((count / maxCount).clamp(0, 1) as double);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text1,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Color(color)),
          ),
        ),
      ],
    );
  }
}
