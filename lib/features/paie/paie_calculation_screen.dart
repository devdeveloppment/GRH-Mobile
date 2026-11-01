import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/paie_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/fiche_paie.dart';
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
      final messenger = ScaffoldMessenger.of(context);
      final filePath = await ref.read(paieNotifierProvider).exportPayrollCSV();
      if (!context.mounted) return;
      if (filePath != null && !kIsWeb) {
        await OpenFilex.open(filePath);
      }
      final err = ref.read(paieNotifierProvider).errorMessage;
      messenger.showSnackBar(
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
                            onPressed: paie.isLoading ? null : onValidate,
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
                            onPressed: paie.isLoading ? null : onExportCsv,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1),
                            ),
                            icon: const Icon(Icons.download_outlined, size: 16),
                            label: const Text('Exporter CSV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 22),

                // ── KPI résumé ──────────────────────────────────────────────
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

                // ── Avertissement réglementaire ─────────────────────────────
                if (paie.bulletins.any((b) => !b.conformeReglementation)) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SIMULATION : les règles de paie (cotisations, impôt) ne sont pas validées par un '
                            'expert-comptable. Ces bulletins ne constituent pas des bulletins légaux.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Bulletins ───────────────────────────────────────────────
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
                        style: TextStyle(fontSize: 13, color: AppColors.text2),
                      ),
                    ),
                  )
                else
                  ...paie.bulletins.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _PayslipDocCard(
                        item: item,
                        onDownload: () async {
                          final messenger = ScaffoldMessenger.of(context);
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
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Bulletin généré et prêt à être consulté.'),
                            ),
                          );
                        },
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

// ── Bouton sélecteur de période ─────────────────────────────────────────────
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

// ── Bulletin de paie — document structuré ───────────────────────────────────
class _PayslipDocCard extends StatelessWidget {
  const _PayslipDocCard({required this.item, required this.onDownload});

  final FichePaie item;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final baseSalary = item.salaireBrut - item.indemnites;
    final totalRetenues = item.cotisations + item.impots;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── En-tête document ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BULLETIN DE PAIE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.nomEmploye ?? 'Employé',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Période : ${item.periode}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
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
                          : 'En attente',
                  type: item.validee
                      ? 'success'
                      : item.calculee
                          ? 'active'
                          : 'pending',
                ),
              ],
            ),
          ),

          // ── Corps du bulletin ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rémunérations
                const _PaySectionLabel('RÉMUNÉRATIONS'),
                const SizedBox(height: 10),
                _PayLineItem(
                  label: 'Salaire de base',
                  value: AppFormatters.currency(baseSalary < 0 ? 0 : baseSalary),
                ),
                _PayLineItem(
                  label: 'Indemnités',
                  value: AppFormatters.currency(item.indemnites),
                ),
                const _PayDivider(),
                _PayLineItem(
                  label: 'Total brut',
                  value: AppFormatters.currency(item.salaireBrut),
                  isBold: true,
                ),
                const SizedBox(height: 20),

                // Retenues
                const _PaySectionLabel('RETENUES'),
                const SizedBox(height: 10),
                _PayLineItem(
                  label: 'Cotisations salariales',
                  value: AppFormatters.currency(item.cotisations),
                  isDeduction: true,
                ),
                _PayLineItem(
                  label: 'Impôt sur le revenu',
                  value: AppFormatters.currency(item.impots),
                  isDeduction: true,
                ),
                const _PayDivider(),
                _PayLineItem(
                  label: 'Total retenues',
                  value: AppFormatters.currency(totalRetenues),
                  isBold: true,
                  isDeduction: true,
                ),
                const SizedBox(height: 20),

                // Net à payer — encadré
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.25),
                        width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NET À PAYER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Montant versé à l\'employé',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.text2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppFormatters.currency(item.salaireNet),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Actions (Wrap : passe à la ligne sur petit écran au lieu de déborder)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: onDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            size: 16),
                        label: const Text(
                          'Télécharger PDF',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sous-widgets du bulletin ─────────────────────────────────────────────────

class _PaySectionLabel extends StatelessWidget {
  const _PaySectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.text2,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _PayDivider extends StatelessWidget {
  const _PayDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, thickness: 0.5, color: AppColors.border),
    );
  }
}

class _PayLineItem extends StatelessWidget {
  const _PayLineItem({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isDeduction = false,
  });

  final String label;
  final String value;
  final bool isBold;
  final bool isDeduction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isBold ? AppColors.text1 : AppColors.text2,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            isDeduction ? '- $value' : value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isDeduction ? AppColors.error : AppColors.text1,
            ),
          ),
        ],
      ),
    );
  }
}
