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
import 'package:grh_mobile/shared/widgets/section_header.dart';

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
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(file == null ? 'Export impossible.' : 'Export $format prêt.')),
      );
    }

    return Scaffold(
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.rapports,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: Builder(
        builder: (scaffoldContext) => GrhAppBar(
          title: 'Rapports RH',
          userName: auth.user?.fullName,
          onMenuTap: isWide ? null : () => Scaffold.of(scaffoldContext).openDrawer(),
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
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isWide ? 280 : double.infinity,
                      child: KpiCard(
                        title: 'Masse salariale',
                        value: AppFormatters.currency(summary?.payrollMass ?? 0),
                        icon: Icons.payments_outlined,
                        color: AppColors.primary,
                        trend: 8.1,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 280 : double.infinity,
                      child: KpiCard(
                        title: 'Taux de présence',
                        value: '${(summary?.attendanceRate ?? 0).toStringAsFixed(1)}%',
                        icon: Icons.analytics_outlined,
                        color: AppColors.info,
                        trend: 2.2,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 280 : double.infinity,
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
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Exports disponibles'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => export('pdf'),
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: const Text('Rapport PDF'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => export('excel'),
                              icon: const Icon(Icons.grid_on_outlined),
                              label: const Text('Rapport Excel'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const ListTile(
                          leading: Icon(Icons.description_outlined),
                          title: Text('Rapport de masse salariale'),
                          subtitle: Text('Vue consolidée mensuelle par département.'),
                        ),
                        const ListTile(
                          leading: Icon(Icons.groups_outlined),
                          title: Text('Rapport d’effectif'),
                          subtitle: Text('Analyse des recrutements, départs et turn-over.'),
                        ),
                        const ListTile(
                          leading: Icon(Icons.fact_check_outlined),
                          title: Text('Rapport de présence'),
                          subtitle: Text('Punctualité, assiduité et anomalies de pointage.'),
                        ),
                      ],
                    ),
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
