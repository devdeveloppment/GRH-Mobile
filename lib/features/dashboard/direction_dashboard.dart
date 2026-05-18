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
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/kpi_card.dart';
import 'package:grh_mobile/shared/widgets/section_header.dart';

class DirectionDashboardScreen extends ConsumerWidget {
  const DirectionDashboardScreen({
    super.key,
    this.isReportMode = false,
  });

  final bool isReportMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final dashboard = ref.watch(dashboardNotifierProvider);
    final summary = dashboard.summary;
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final title = isReportMode ? 'Rapports Exécutifs' : 'Dashboard Direction';

    Future<void> export(String format) async {
      final path = await ref.read(apiServiceProvider).downloadFile(
            '/reports/export?format=$format',
            'rapport-direction.${format == 'excel' ? 'xlsx' : 'pdf'}',
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path == null
              ? 'Export impossible.'
              : 'Export $format généré avec succès.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: isReportMode
                    ? AppRoutes.rapports
                    : AppRoutes.directionDashboard,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: GrhAppBar(
        title: title,
        userName: auth.user?.fullName,
        onMenuTap: isWide ? null : () => Scaffold.of(context).openDrawer(),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(
              currentRoute: isReportMode
                  ? AppRoutes.rapports
                  : AppRoutes.directionDashboard,
              role: auth.role!,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: isWide ? 260 : double.infinity,
                        child: KpiCard(
                          title: 'Masse Salariale',
                          value:
                              AppFormatters.currency(summary?.payrollMass ?? 0),
                          icon: Icons.payments_outlined,
                          color: AppColors.primary,
                          trend: 8.6,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 260 : double.infinity,
                        child: KpiCard(
                          title: 'Taux de présence',
                          value:
                              '${(summary?.attendanceRate ?? 0).toStringAsFixed(1)}%',
                          icon: Icons.checklist_rtl_outlined,
                          color: AppColors.success,
                          trend: 1.8,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 260 : double.infinity,
                        child: KpiCard(
                          title: 'Congés accordés',
                          value: '${summary?.approvedLeaves ?? 0}',
                          icon: Icons.event_available_outlined,
                          color: AppColors.warning,
                          trend: 3.2,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 260 : double.infinity,
                        child: KpiCard(
                          title: 'Turnover',
                          value:
                              '${(summary?.turnoverRate ?? 0).toStringAsFixed(1)}%',
                          icon: Icons.sync_alt_outlined,
                          color: AppColors.accent,
                          trend: -0.7,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () => export('pdf'),
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              size: 16),
                          label: const Text('Exporter PDF'),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () => export('excel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.border, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.table_view_outlined, size: 16),
                          label: const Text('Exporter Excel'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _ChartCard(
                                title: 'Évolution de la masse salariale',
                                child: _PayrollAreaChart(
                                  points:
                                      summary?.payrollEvolution ?? const [],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _ChartCard(
                                title: isReportMode
                                    ? 'Répartition RH'
                                    : 'Répartition par département',
                                actionLabel:
                                    !isReportMode ? 'Voir RH' : null,
                                onAction: !isReportMode
                                    ? () => context.go(AppRoutes.rhDashboard)
                                    : null,
                                child: _DepartmentDonutChart(
                                  points:
                                      summary?.departmentBreakdown ?? const [],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _ChartCard(
                              title: 'Évolution de la masse salariale',
                              child: _PayrollAreaChart(
                                points: summary?.payrollEvolution ?? const [],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _ChartCard(
                              title: isReportMode
                                  ? 'Répartition RH'
                                  : 'Répartition par département',
                              actionLabel: !isReportMode ? 'Voir RH' : null,
                              onAction: !isReportMode
                                  ? () => context.go(AppRoutes.rhDashboard)
                                  : null,
                              child: _DepartmentDonutChart(
                                points:
                                    summary?.departmentBreakdown ?? const [],
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
          const SizedBox(height: 20),
          SizedBox(height: 260, child: child),
        ],
      ),
    );
  }
}

class _PayrollAreaChart extends StatelessWidget {
  const _PayrollAreaChart({required this.points});

  final List<DashboardPoint> points;

  @override
  Widget build(BuildContext context) {
    final values = points.isEmpty
        ? const [
            DashboardPoint(label: 'Nov', value: 6200000),
            DashboardPoint(label: 'Déc', value: 6800000),
            DashboardPoint(label: 'Jan', value: 7000000),
            DashboardPoint(label: 'Fév', value: 7250000),
            DashboardPoint(label: 'Mar', value: 7600000),
            DashboardPoint(label: 'Avr', value: 7900000),
          ]
        : points;

    return LineChart(
      LineChartData(
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= values.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    values[index].label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.text2),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 54,
              getTitlesWidget: (value, meta) => Text(
                '${(value / 1000000).toStringAsFixed(1)}M',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.text2),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i].value),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: AppColors.primary,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentDonutChart extends StatelessWidget {
  const _DepartmentDonutChart({required this.points});

  final List<DashboardPoint> points;

  @override
  Widget build(BuildContext context) {
    final values = points;
    const colors = <Color>[
      AppColors.primary,
      AppColors.accent,
      AppColors.warning,
      AppColors.success,
    ];

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
              centerSpaceRadius: 46,
              sectionsSpace: 2,
              sections: [
                for (int index = 0; index < values.length; index++)
                  PieChartSectionData(
                    color: colors[index % colors.length],
                    value: values[index].value,
                    title: '${values[index].value.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int index = 0; index < values.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          values[index].label,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.text1),
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
