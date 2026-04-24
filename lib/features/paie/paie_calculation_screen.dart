import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/paie_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

class PaieCalculationScreen extends ConsumerWidget {
  const PaieCalculationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final paie = ref.watch(paieNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    Future<void> pickMonth() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: paie.selectedPeriod,
        firstDate: DateTime(2021),
        lastDate: DateTime(2100),
        locale: const Locale('fr', 'TG'),
      );
      if (picked != null) {
        await ref.read(paieNotifierProvider).loadForPeriod(DateTime(picked.year, picked.month));
      }
    }

    return Scaffold(
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.paie,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: GrhAppBar(
          title: 'Calcul de Paie',
          userName: auth.user?.fullName,
          onMenuTap: isWide ? null : () => Scaffold.of(context).openDrawer(),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.paie, role: auth.role!),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: pickMonth,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(AppFormatters.monthYear(paie.selectedPeriod)),
                    ),
                    ElevatedButton.icon(
                      onPressed: paie.isLoading
                          ? null
                          : () async {
                              await ref.read(paieNotifierProvider).calculateAll();
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Calcul de paie effectué avec succès.')),
                              );
                            },
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('CALCULER TOUT'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (paie.isLoading && paie.bulletins.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  ...paie.bulletins.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.nomEmploye ?? 'Employé',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(item.periode),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(
                                    label: item.calculee ? 'Calculé' : 'Non calculé',
                                    type: item.calculee ? 'success' : 'warning',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: [
                                  _PayMetric(label: 'Salaire brut', value: AppFormatters.currency(item.salaireBrut)),
                                  _PayMetric(label: 'CNSS', value: AppFormatters.currency(item.cotisations)),
                                  _PayMetric(label: 'Impôts', value: AppFormatters.currency(item.impots)),
                                  _PayMetric(label: 'Indemnités', value: AppFormatters.currency(item.indemnites)),
                                  _PayMetric(label: 'Salaire net', value: AppFormatters.currency(item.salaireNet)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final filePath = await ref.read(paieNotifierProvider).downloadPayslip(
                                          item.id,
                                          item.nomEmploye ?? 'employe',
                                        );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    if (filePath != null && !kIsWeb) {
                                      await OpenFilex.open(filePath);
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle_outline, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('Bulletin généré et prêt à être consulté.'),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.picture_as_pdf_outlined),
                                  label: const Text('PDF'),
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _PayMetric extends StatelessWidget {
  const _PayMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
