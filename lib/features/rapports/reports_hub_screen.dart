import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/dashboard_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/kpi_card.dart';

class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final dashboard = ref.watch(dashboardNotifierProvider);
    final summary = dashboard.summary;
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    Future<void> export(String format) async {
      final file = await ref.read(apiServiceProvider).downloadFile(
            '/reports/export?format=$format',
            'rapport-rh.${format == 'excel' ? 'xlsx' : 'pdf'}',
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                file == null ? 'Export impossible.' : 'Export $format prêt.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.rapports,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Rapports RH',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.rapports, role: auth.role!),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: KpiCard(
                        title: 'Masse salariale',
                        value:
                            AppFormatters.currency(summary?.payrollMass ?? 0),
                        icon: Icons.payments_outlined,
                        color: AppColors.primary,
                        trend: 8.1,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: KpiCard(
                        title: 'Taux de présence',
                        value:
                            '${(summary?.attendanceRate ?? 0).toStringAsFixed(1)}%',
                        icon: Icons.analytics_outlined,
                        color: AppColors.accent,
                        trend: 2.2,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: KpiCard(
                        title: 'Congés accordés',
                        value: '${summary?.approvedLeaves ?? 0}',
                        icon: Icons.event_available_outlined,
                        color: AppColors.warning,
                        trend: 1.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exports disponibles',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                              label: const Text('Rapport PDF'),
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
                              icon: const Icon(Icons.grid_on_outlined, size: 16),
                              label: const Text('Rapport Excel'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(
                          height: 1, thickness: 0.5, color: AppColors.border),
                      const SizedBox(height: 12),
                      _ReportTile(
                        icon: Icons.description_outlined,
                        title: 'Rapport de masse salariale',
                        subtitle: 'Vue consolidée mensuelle par département.',
                      ),
                      _ReportTile(
                        icon: Icons.groups_outlined,
                        title: "Rapport d'effectif",
                        subtitle:
                            'Analyse des recrutements, départs et turn-over.',
                      ),
                      _ReportTile(
                        icon: Icons.fact_check_outlined,
                        title: 'Rapport de présence',
                        subtitle:
                            'Ponctualité, assiduité et anomalies de pointage.',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 0.5, color: AppColors.border),
      ],
    );
  }
}
