import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/paie_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

class PaieCalculationScreen extends ConsumerWidget {
  const PaieCalculationScreen({super.key});

  static bool _canValidate(UserRole? role) =>
      role == UserRole.admin || role == UserRole.rhManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final paie = ref.watch(paieNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1120;

    Future<void> onValidate() async {
      await ref.read(paieNotifierProvider).validatePayroll();
      if (!context.mounted) return;
      final err = ref.read(paieNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Paie du mois validée avec succès.'),
          backgroundColor: err != null ? AppColors.error : null,
        ),
      );
    }

    Future<void> onExportCsv() async {
      final filePath =
          await ref.read(paieNotifierProvider).exportPayrollCSV();
      if (!context.mounted) return;
      if (filePath != null && !kIsWeb) {
        await OpenFilex.open(filePath);
      }
      final err = ref.read(paieNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Export CSV prêt.'),
          backgroundColor: err != null ? AppColors.error : null,
        ),
      );
    }

    Future<void> pickMonth() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: paie.selectedPeriod,
        firstDate: DateTime(2021),
        lastDate: DateTime(2100),
        locale: const Locale('fr', 'TG'),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              secondary: AppColors.accent,
              onSecondary: Colors.white,
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        await ref
            .read(paieNotifierProvider)
            .loadForPeriod(DateTime(picked.year, picked.month));
      }
    }

    final totalNet =
        paie.bulletins.fold<double>(0, (sum, item) => sum + item.salaireNet);
    final totalBrut =
        paie.bulletins.fold<double>(0, (sum, item) => sum + item.salaireBrut);

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.paie,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: Builder(
          builder: (scaffoldContext) => GrhAppBar(
            title: 'Paie',
            userName: auth.user?.fullName,
            onMenuTap:
                isWide ? null : () => Scaffold.of(scaffoldContext).openDrawer(),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.paie, role: auth.role!),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GrhPageHeader(
                  title: 'Calcul et suivi de la paie',
                  subtitle:
                      'Vue synthèse des bulletins, masse salariale mensuelle et téléchargement PDF.',
                  trailing: isWide
                      ? Wrap(
                          spacing: 10,
                          children: [
                            _PeriodButton(
                              label: AppFormatters.monthYear(
                                  paie.selectedPeriod),
                              onTap: pickMonth,
                            ),
                            ElevatedButton.icon(
                              onPressed: paie.isLoading
                                  ? null
                                  : () async {
                                      await ref
                                          .read(paieNotifierProvider)
                                          .calculateAll();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Calcul de paie effectué avec succès.'),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.calculate_outlined,
                                  size: 16),
                              label: const Text('Calculer tout'),
                            ),
                            if (_canValidate(auth.role)) ...[
                              ElevatedButton.icon(
                                onPressed:
                                    paie.isLoading ? null : onValidate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.check_circle_outline,
                                    size: 16),
                                label: const Text('Valider le mois'),
                              ),
                              OutlinedButton.icon(
                                onPressed:
                                    paie.isLoading ? null : onExportCsv,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                      color: AppColors.primary, width: 1),
                                ),
                                icon: const Icon(Icons.download_outlined,
                                    size: 16),
                                label: const Text('Exporter CSV'),
                              ),
                            ],
                          ],
                        )
                      : null,
                ),
                if (!isWide) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _PeriodButton(
                          label: AppFormatters.monthYear(paie.selectedPeriod),
                          onTap: pickMonth,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: paie.isLoading
                              ? null
                              : () async {
                                  await ref
                                      .read(paieNotifierProvider)
                                      .calculateAll();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Calcul de paie effectué avec succès.')),
                                  );
                                },
                          icon: const Icon(Icons.calculate_outlined, size: 16),
                          label: const Text('Calculer tout'),
                        ),
                      ),
                    ],
                  ),
                  if (_canValidate(auth.role)) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                paie.isLoading ? null : onValidate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.check_circle_outline,
                                size: 16),
                            label: const Text('Valider le mois'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                paie.isLoading ? null : onExportCsv,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1),
                            ),
                            icon: const Icon(Icons.download_outlined,
                                size: 16),
                            label: const Text('Exporter CSV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 22),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: isWide ? 220 : double.infinity,
                      child: GrhMiniMetric(
                        label: 'Bulletins',
                        value: '${paie.bulletins.length}',
                        color: AppColors.primary,
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 220 : double.infinity,
                      child: GrhMiniMetric(
                        label: 'Total net',
                        value: AppFormatters.currency(totalNet),
                        color: AppColors.accent,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 220 : double.infinity,
                      child: GrhMiniMetric(
                        label: 'Total brut',
                        value: AppFormatters.currency(totalBrut),
                        color: AppColors.success,
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (paie.isLoading && paie.bulletins.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (paie.bulletins.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucun bulletin pour cette période.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text2,
                        ),
                      ),
                    ),
                  )
                else
                  ...paie.bulletins.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GrhSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.border, width: 0.5),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nomEmploye ?? 'Employé',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.periode,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.text2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  label: item.validee
                                      ? 'Validé'
                                      : item.calculee
                                          ? 'Calculé'
                                          : 'Non calculé',
                                  type: item.validee
                                      ? 'success'
                                      : item.calculee
                                          ? 'active'
                                          : 'pending',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.border,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _PayMetric(
                                    label: 'Salaire brut',
                                    value: AppFormatters.currency(
                                        item.salaireBrut)),
                                _PayMetric(
                                    label: 'CNSS',
                                    value: AppFormatters.currency(
                                        item.cotisations),
                                    isDeduction: true),
                                _PayMetric(
                                    label: 'Impôts',
                                    value:
                                        AppFormatters.currency(item.impots),
                                    isDeduction: true),
                                _PayMetric(
                                    label: 'Indemnités',
                                    value: AppFormatters.currency(
                                        item.indemnites)),
                                _PayMetric(
                                    label: 'Salaire net',
                                    value: AppFormatters.currency(
                                        item.salaireNet),
                                    highlight: true),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final filePath = await ref
                                        .read(paieNotifierProvider)
                                        .downloadPayslip(
                                          item.id,
                                          item.nomEmploye ?? 'employe',
                                        );
                                    if (!context.mounted) return;
                                    if (filePath != null && !kIsWeb) {
                                      await OpenFilex.open(filePath);
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Bulletin généré et prêt à être consulté.'),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      size: 16),
                                  label: const Text(
                                    'Télécharger PDF',
                                    style: TextStyle(fontSize: 12),
                                  ),
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
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayMetric extends StatelessWidget {
  const _PayMetric({
    required this.label,
    required this.value,
    this.isDeduction = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool isDeduction;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color accent = highlight
        ? AppColors.primary
        : isDeduction
            ? AppColors.error
            : AppColors.text2;

    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withOpacity(0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? AppColors.primary.withOpacity(0.2) : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: accent,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : AppColors.text1,
            ),
          ),
        ],
      ),
    );
  }
}
