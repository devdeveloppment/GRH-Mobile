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
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
import 'package:grh_mobile/shared/widgets/kpi_card.dart';

class RhDashboardScreen extends ConsumerWidget {
  const RhDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth      = ref.watch(authNotifierProvider);
    final dashboard = ref.watch(dashboardNotifierProvider);
    final summary   = dashboard.summary;
    final isWide    = MediaQuery.sizeOf(context).width >= 1120;

    return Scaffold(
      backgroundColor: AppColors.surface,
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
            userName: 'Bienvenue sur votre espace RH',
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
            actions: [
              IconButton(
                onPressed: () {},
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
            child: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () => ref.read(dashboardNotifierProvider).load(),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // ── En-tête ────────────────────────────────────────────
                  GrhPageHeader(
                    title: 'Vue opérationnelle RH',
                    subtitle:
                        'Suivi global des effectifs, présences, congés et paie au '
                        '${AppFormatters.longDate(DateTime.now())}.',
                    trailing: isWide
                        ? ElevatedButton.icon(
                            onPressed: () => context.go(AppRoutes.employees),
                            icon: const Icon(Icons.people_alt_outlined, size: 16),
                            label: const Text('Employés'),
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // ── KPI cards ──────────────────────────────────────────
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.6 : 1.2,
                    children: [
                      KpiCard(
                        title: 'Employés',
                        value: '${summary?.totalEmployees ?? 0}',
                        icon: Icons.groups_2_outlined,
                        color: AppColors.primary,
                        trend: 4.8,
                        isLoading: dashboard.isLoading && summary == null,
                      ),
                      KpiCard(
                        title: 'Taux de présence',
                        value:
                            '${(summary?.attendanceRate ?? 0).toStringAsFixed(0)}%',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                        trend: 2.4,
                        isLoading: dashboard.isLoading && summary == null,
                      ),
                      KpiCard(
                        title: 'Demandes de congés',
                        value: '${summary?.pendingLeaves ?? 0}',
                        icon: Icons.event_available_outlined,
                        color: AppColors.accent,
                        trend: -1.3,
                        isLoading: dashboard.isLoading && summary == null,
                      ),
                      KpiCard(
                        title: 'Masse salariale',
                        value: AppFormatters.currency(summary?.payrollMass ?? 0),
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.error,
                        trend: 3.6,
                        isLoading: dashboard.isLoading && summary == null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Graphiques ─────────────────────────────────────────
                  Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: GrhSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GrhPageHeader(
                                title: 'Statistiques des présences',
                                subtitle: 'Tendance hebdomadaire des pointages.',
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 260,
                                child: _AttendanceLineChart(
                                  points: summary?.weeklyAttendance ?? const [],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                          width: isWide ? 14 : 0,
                          height: isWide ? 0 : 14),
                      Expanded(
                        flex: 5,
                        child: GrhSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GrhPageHeader(
                                title: 'Répartition par département',
                                subtitle: 'Poids relatif des équipes.',
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 260,
                                child: _DepartmentDonutChart(
                                  points:
                                      summary?.departmentBreakdown ?? const [],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Activités récentes ─────────────────────────────────
                  GrhSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GrhPageHeader(
                          title: 'Activités récentes',
                          subtitle: 'Événements RH les plus récents.',
                        ),
                        const SizedBox(height: 16),
                        if (summary == null && dashboard.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(
                                  color: AppColors.accent),
                            ),
                          )
                        else if (summary?.recentActivities.isEmpty ?? true)
                          const Text(
                            'Aucune activité récente disponible.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.text2),
                          )
                        else
                          ...summary!.recentActivities.take(5).map(
                                (a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    children: [
                                      EmployeeAvatar(
                                        name: a.employeeName,
                                        imageUrl: a.avatarUrl,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.employeeName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.text1,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              a.action,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.text2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        AppFormatters.relativeTime(
                                            a.timestamp),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.text2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),

                  // ── Mini métriques ─────────────────────────────────────
                  if (summary != null) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: isWide ? 240 : double.infinity,
                          child: GrhMiniMetric(
                            label: 'Congés approuvés',
                            value: '${summary.approvedLeaves}',
                            color: AppColors.success,
                            icon: Icons.task_alt_rounded,
                          ),
                        ),
                        SizedBox(
                          width: isWide ? 240 : double.infinity,
                          child: GrhMiniMetric(
                            label: 'Bulletins du mois',
                            value: '${summary.payslipsThisMonth}',
                            color: AppColors.accent,
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                        SizedBox(
                          width: isWide ? 240 : double.infinity,
                          child: GrhMiniMetric(
                            label: 'Turnover',
                            value:
                                '${summary.turnoverRate.toStringAsFixed(1)}%',
                            color: AppColors.warning,
                            icon: Icons.swap_horiz_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Line chart présences ───────────────────────────────────────────────────
class _AttendanceLineChart extends StatelessWidget {
  const _AttendanceLineChart({required this.points});

  final List<DashboardPoint> points;

  @override
  Widget build(BuildContext context) {
    final values = points.isEmpty
        ? const [
            DashboardPoint(label: 'Jan',  value: 28),
            DashboardPoint(label: 'Fév',  value: 64),
            DashboardPoint(label: 'Mar',  value: 48),
            DashboardPoint(label: 'Avr',  value: 73),
            DashboardPoint(label: 'Mai',  value: 61),
            DashboardPoint(label: 'Juin', value: 84),
            DashboardPoint(label: 'Juil', value: 78),
          ]
        : points;

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 30,
              showTitles: true,
              interval: 20,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.text2),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= values.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    values[i].label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.text2),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppColors.accent,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3.5,
                color: AppColors.accent,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            // Aucun gradient — fond de courbe uni semi-transparent
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent.withOpacity(0.08),
            ),
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i].value),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Donut chart départements ───────────────────────────────────────────────
class _DepartmentDonutChart extends StatelessWidget {
  const _DepartmentDonutChart({required this.points});

  final List<DashboardPoint> points;

  static const _palette = <Color>[
    AppColors.primary,
    AppColors.accent,
    AppColors.success,
    AppColors.warning,
    AppColors.text2,
  ];

  @override
  Widget build(BuildContext context) {
    final values = points;

    if (values.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible',
            style: TextStyle(fontSize: 12, color: AppColors.text2)),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                for (var i = 0; i < values.length; i++)
                  PieChartSectionData(
                    color: _palette[i % _palette.length],
                    value: values[i].value,
                    title: '${values[i].value.toStringAsFixed(0)}%',
                    radius: 48,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < values.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          values[i].label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text1,
                          ),
                        ),
                      ),
                      Text(
                        '${values[i].value.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tile insight ─────────────────────────────────────────────────────────────
