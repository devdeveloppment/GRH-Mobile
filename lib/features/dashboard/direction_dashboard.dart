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
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path == null ? 'Export impossible.' : 'Export $format généré avec succès.'),
        ),
      );
    }

    return Scaffold(
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: isReportMode ? AppRoutes.rapports : AppRoutes.directionDashboard,
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
              currentRoute: isReportMode ? AppRoutes.rapports : AppRoutes.directionDashboard,
              role: auth.role!,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: isWide ? 280 : double.infinity,
                        child: KpiCard(
                          title: 'Masse Salariale',
                          value: AppFormatters.currency(summary?.payrollMass ?? 0),
                          icon: Icons.payments_outlined,
                          color: AppColors.primary,
                          trend: 8.6,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 280 : double.infinity,
                        child: KpiCard(
                          title: 'Taux de présence',
                          value: '${(summary?.attendanceRate ?? 0).toStringAsFixed(1)}%',
                          icon: Icons.checklist_rtl_outlined,
                          color: AppColors.success,
                          trend: 1.8,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 280 : double.infinity,
                        child: KpiCard(
                          title: 'Congés accordés',
                          value: '${summary?.approvedLeaves ?? 0}',
                          icon: Icons.event_available_outlined,
                          color: AppColors.warning,
                          trend: 3.2,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 280 : double.infinity,
                        child: KpiCard(
                          title: 'Turnover',
                          value: '${(summary?.turnoverRate ?? 0).toStringAsFixed(1)}%',
                          icon: Icons.sync_alt_outlined,
                          color: AppColors.secondary,
                          trend: -0.7,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => export('pdf'),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Exporter PDF'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => export('excel'),
                        icon: const Icon(Icons.table_view_outlined),
                        label: const Text('Exporter Excel'),
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
                                const SectionHeader(title: 'Évolution de la masse salariale'),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 280,
                                  child: _PayrollAreaChart(
                                    points: summary?.payrollEvolution ?? const [],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isWide ? 18 : 0, height: isWide ? 0 : 18),
                      Expanded(
                        flex: 4,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: isReportMode ? 'Répartition RH' : 'Répartition par département',
                                  actionLabel: !isReportMode ? 'Voir RH' : null,
                                  onAction: !isReportMode ? () => context.go(AppRoutes.rhDashboard) : null,
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 280,
                                  child: _DepartmentDonutChart(
                                    points: summary?.departmentBreakdown ?? const [],
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
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  child: Text(values[index].label),
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
                style: Theme.of(context).textTheme.bodySmall,
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
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.28),
                  AppColors.accent.withOpacity(0.08),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
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
    final values = points.isEmpty
        ? const [
            DashboardPoint(label: 'Finance', value: 28),
            DashboardPoint(label: 'Commercial', value: 22),
            DashboardPoint(label: 'Production', value: 30),
            DashboardPoint(label: 'Support', value: 20),
          ]
        : points;
    final colors = <Color>[
      AppColors.primary,
      AppColors.secondary,
      AppColors.warning,
      AppColors.info,
    ];

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 50,
              sectionsSpace: 3,
              sections: [
                for (int index = 0; index < values.length; index++)
                  PieChartSectionData(
                    color: colors[index % colors.length],
                    value: values[index].value,
                    title: '${values[index].value.toStringAsFixed(0)}%',
                    radius: 54,
                    titleStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int index = 0; index < values.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(values[index].label)),
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
