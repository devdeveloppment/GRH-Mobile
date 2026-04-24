import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/dashboard_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/dashboard_summary.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/kpi_card.dart';
import 'package:grh_mobile/shared/widgets/loading_overlay.dart';
import 'package:grh_mobile/shared/widgets/section_header.dart';

class RhDashboardScreen extends ConsumerWidget {
  const RhDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final dashboard = ref.watch(dashboardNotifierProvider);
    final summary = dashboard.summary;
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
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
        preferredSize: const Size.fromHeight(76),
        child: Builder(
          builder: (scaffoldContext) => GrhAppBar(
            title: 'Dashboard RH',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(scaffoldContext).openDrawer(),
            actions: [
              IconButton(
                onPressed: () {},
                icon: Badge(
                  backgroundColor: AppColors.secondary,
                  label: const Text('3'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: EmployeeAvatar(
                  name: auth.user?.fullName ?? 'Utilisateur',
                  imageUrl: auth.user?.avatarUrl,
                  size: 38,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.rhDashboard, role: auth.role!),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(dashboardNotifierProvider).load(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: LoadingOverlay(
                  isLoading: dashboard.isLoading && summary == null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vue opérationnelle RH',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormatters.longDate(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                      const SizedBox(height: 22),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.55 : 1.1,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          KpiCard(
                            title: 'Total Employés',
                            value: '${summary?.totalEmployees ?? 0}',
                            icon: Icons.people_alt_outlined,
                            color: AppColors.navy,
                            trend: 4.8,
                            isLoading: dashboard.isLoading && summary == null,
                          ),
                          KpiCard(
                            title: 'Présents Aujourd’hui',
                            value: '${summary?.presentToday ?? 0}',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            trend: 2.3,
                            isLoading: dashboard.isLoading && summary == null,
                          ),
                          KpiCard(
                            title: 'Congés en Attente',
                            value: '${summary?.pendingLeaves ?? 0}',
                            icon: Icons.hourglass_top_rounded,
                            color: AppColors.warning,
                            trend: -1.2,
                            isLoading: dashboard.isLoading && summary == null,
                          ),
                          KpiCard(
                            title: 'Bulletins du Mois',
                            value: '${summary?.payslipsThisMonth ?? 0}',
                            icon: Icons.description_outlined,
                            color: AppColors.info,
                            trend: 5.1,
                            isLoading: dashboard.isLoading && summary == null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: 'Présences de la semaine',
                                      actionLabel: 'Voir détail',
                                      onAction: () => context.go(AppRoutes.rapports),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      height: 260,
                                      child: _AttendanceChart(points: summary?.weeklyAttendance ?? const []),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isWide ? 18 : 0, height: isWide ? 0 : 18),
                          Expanded(
                            flex: 5,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(title: 'Activités Récentes'),
                                    const SizedBox(height: 12),
                                    if (summary?.recentActivities.isEmpty ?? true)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Text(
                                          'Aucune activité récente disponible.',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      )
                                    else
                                      ...summary!.recentActivities.take(6).map(
                                            (activity) => Padding(
                                              padding: const EdgeInsets.only(bottom: 14),
                                              child: Row(
                                                children: [
                                                  EmployeeAvatar(
                                                    name: activity.employeeName,
                                                    imageUrl: activity.avatarUrl,
                                                    size: 42,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          activity.employeeName,
                                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                                fontWeight: FontWeight.w700,
                                                              ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(activity.action),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    AppFormatters.relativeTime(activity.timestamp),
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  const _AttendanceChart({required this.points});

  final List<DashboardPoint> points;

  @override
  Widget build(BuildContext context) {
    final chartPoints = points.isEmpty
        ? const [
            DashboardPoint(label: 'Lun', value: 20),
            DashboardPoint(label: 'Mar', value: 24),
            DashboardPoint(label: 'Mer', value: 22),
            DashboardPoint(label: 'Jeu', value: 27),
            DashboardPoint(label: 'Ven', value: 25),
          ]
        : points;

    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        barGroups: [
          for (int index = 0; index < chartPoints.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: chartPoints[index].value,
                  width: 18,
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [AppColors.navy, AppColors.accent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartPoints.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(chartPoints[index].label),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
