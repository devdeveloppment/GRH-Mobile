import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/dashboard_provider.dart';
import 'package:grh_mobile/core/providers/report_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/kpi_card.dart';

class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen> {
  static const _types = ['PRESENCES', 'CONGES', 'PAIE', 'EFFECTIFS'];
  static const _typeLabels = {
    'PRESENCES': 'Présences',
    'CONGES': 'Congés',
    'PAIE': 'Paie',
    'EFFECTIFS': 'Effectifs',
  };
  static const _formats = ['PDF', 'CSV'];

  String _type = 'PRESENCES';
  String _format = 'PDF';
  String? _service;
  late DateTime _debut;
  late DateTime _fin;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _debut = DateTime(now.year, now.month, 1);
    _fin = now;
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2021),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _debut, end: _fin),
      locale: const Locale('fr', 'TG'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.accent,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _debut = picked.start;
        _fin = picked.end;
      });
    }
  }

  Future<void> _generate() async {
    final filePath = await ref.read(reportNotifierProvider).generateAndDownload(
          type: _type,
          debut: _debut,
          fin: _fin,
          format: _format,
          service: _service,
        );
    if (!mounted) return;
    final err = ref.read(reportNotifierProvider).errorMessage;
    if (filePath != null && !kIsWeb) {
      await OpenFilex.open(filePath);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Rapport $_format généré avec succès.'),
        backgroundColor: err != null ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final dashboard = ref.watch(dashboardNotifierProvider);
    final report = ref.watch(reportNotifierProvider);
    final summary = dashboard.summary;
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

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
                // ── KPI ────────────────────────────────────────────────────
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: KpiCard(
                        title: 'Masse salariale',
                        value: AppFormatters.currency(summary?.payrollMass ?? 0),
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

                // ── Formulaire de génération ────────────────────────────────
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
                        'Générer un rapport personnalisé',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Type + Format
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          _FormField(
                            label: 'Type de rapport',
                            width: isWide ? 220 : double.infinity,
                            child: DropdownButtonFormField<String>(
                              value: _type,
                              decoration: _inputDecoration(),
                              items: _types
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(_typeLabels[t] ?? t,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _type = v!),
                            ),
                          ),
                          _FormField(
                            label: 'Format',
                            width: isWide ? 140 : double.infinity,
                            child: DropdownButtonFormField<String>(
                              value: _format,
                              decoration: _inputDecoration(),
                              items: _formats
                                  .map((f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _format = v!),
                            ),
                          ),
                          _FormField(
                            label: 'Service (optionnel)',
                            width: isWide ? 220 : double.infinity,
                            child: DropdownButtonFormField<String?>(
                              value: _service,
                              decoration: _inputDecoration(hint: 'Tous les services'),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Tous les services',
                                      style: TextStyle(fontSize: 13)),
                                ),
                                ...report.services.map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s,
                                          style: const TextStyle(fontSize: 13)),
                                    )),
                              ],
                              onChanged: (v) => setState(() => _service = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Sélecteur de période
                      GestureDetector(
                        onTap: _pickRange,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.date_range_outlined,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                '${AppFormatters.shortDate(_debut)}  →  ${AppFormatters.shortDate(_fin)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.text1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.expand_more,
                                  size: 16, color: AppColors.text2),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Bouton Générer
                      SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: report.isLoading ? null : _generate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: report.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _format == 'PDF'
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.grid_on_outlined,
                                  size: 16,
                                ),
                          label: Text(
                            report.isLoading
                                ? 'Génération en cours…'
                                : 'Générer le rapport ${_typeLabels[_type] ?? _type}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Exports rapides existants ───────────────────────────────
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
                        'Exports rapides',
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
                              onPressed: report.isLoading
                                  ? null
                                  : () async {
                                      final file = await ref
                                          .read(reportNotifierProvider)
                                          .exportLegacy('pdf');
                                      if (!context.mounted) return;
                                      if (file != null && !kIsWeb) {
                                        await OpenFilex.open(file);
                                      }
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(file == null
                                            ? 'Export impossible.'
                                            : 'Rapport PDF prêt.'),
                                      ));
                                    },
                              icon: const Icon(Icons.picture_as_pdf_outlined,
                                  size: 16),
                              label: const Text('Vue globale PDF'),
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: report.isLoading
                                  ? null
                                  : () async {
                                      final file = await ref
                                          .read(reportNotifierProvider)
                                          .exportLegacy('excel');
                                      if (!context.mounted) return;
                                      if (file != null && !kIsWeb) {
                                        await OpenFilex.open(file);
                                      }
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(file == null
                                            ? 'Export impossible.'
                                            : 'Rapport Excel prêt.'),
                                      ));
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: AppColors.border, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.grid_on_outlined, size: 16),
                              label: const Text('Vue globale Excel'),
                            ),
                          ),
                        ],
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

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
      );
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.child,
    required this.width,
  });

  final String label;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.text2,
            ),
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}
