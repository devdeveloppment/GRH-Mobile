import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/conge_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/conge.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/confirm_dialog.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

// ── Types de congé disponibles ───────────────────────────────────────────────
const _congeTypes = [
  ('Annuel', 'Congé annuel', Icons.beach_access_outlined),
  ('Maladie', 'Maladie', Icons.local_hospital_outlined),
  ('Maternite', 'Maternité', Icons.child_care_outlined),
  ('Sans Solde', 'Sans solde', Icons.money_off_outlined),
];

class CongeRequestScreen extends ConsumerStatefulWidget {
  const CongeRequestScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<CongeRequestScreen> createState() => _CongeRequestScreenState();
}

class _CongeRequestScreenState extends ConsumerState<CongeRequestScreen> {
  final _motifController = TextEditingController();
  String _typeConge = 'Annuel';
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final notifier = ref.watch(congeNotifierProvider);
    final role = auth.role ?? UserRole.employee;
    final isEmployee = role == UserRole.employee;
    final isWide = MediaQuery.sizeOf(context).width >= 1120;
    final content = isEmployee
        ? _buildEmployeeContent(context, notifier)
        : _buildRhContent(context, notifier);

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.conges,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: Builder(
          builder: (scaffoldContext) => GrhAppBar(
            title: 'Congés',
            userName: auth.user?.fullName,
            onMenuTap:
                isWide ? null : () => Scaffold.of(scaffoldContext).openDrawer(),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.conges, role: auth.role!),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildEmployeeContent(BuildContext context, CongeNotifier notifier) {
    final selectedDays =
        _dateRange == null ? 0 : _dateRange!.duration.inDays + 1;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── En-tête ──────────────────────────────────────────────────────────
        const GrhPageHeader(
          title: 'Demande de congé',
          subtitle:
              'Renseignez le type, la période et le motif de votre absence.',
        ),
        const SizedBox(height: 20),

        // ── Formulaire ────────────────────────────────────────────────────────
        Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bandeau titre formulaire
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_available_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouvelle demande',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text1,
                          ),
                        ),
                        Text(
                          'Tous les champs marqués sont requis',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Type de congé ────────────────────────────────────────
                    const Text(
                      'Type de congé *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CongeTypeSelector(
                      selected: _typeConge,
                      onChanged: (t) => setState(() => _typeConge = t),
                    ),
                    const SizedBox(height: 20),

                    // ── Période ──────────────────────────────────────────────
                    const Text(
                      'Période souhaitée *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DateRangePicker(
                      range: _dateRange,
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 30)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: _dateRange,
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
                          setState(() => _dateRange = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Motif ────────────────────────────────────────────────
                    const Text(
                      'Motif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _motifController,
                      minLines: 3,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Précisez le motif de votre absence (optionnel)…',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.border, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.border, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Solde + résumé ───────────────────────────────────────
                    _SoldeCard(
                      solde: notifier.soldeRestant,
                      selectedDays: selectedDays,
                    ),
                    const SizedBox(height: 20),

                    // ── Bouton soumettre ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: notifier.isLoading
                            ? null
                            : () async {
                                if (_dateRange == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Veuillez choisir une période.')),
                                  );
                                  return;
                                }
                                final ok = await ref
                                    .read(congeNotifierProvider)
                                    .submitRequest(
                                      typeConge: _typeConge,
                                      dateDebut: _dateRange!.start,
                                      dateFin: _dateRange!.end,
                                      motif: _motifController.text.trim().isEmpty
                                          ? null
                                          : _motifController.text.trim(),
                                    );
                                if (!ok || !mounted) return;
                                _motifController.clear();
                                setState(() => _dateRange = null);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: notifier.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Soumettre la demande',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // ── Historique des demandes ──────────────────────────────────────────
        const GrhPageHeader(
          title: 'Suivi des demandes',
          subtitle: 'Statuts en attente, approuvés ou rejetés.',
        ),
        const SizedBox(height: 16),
        if (notifier.demandes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Center(
              child: Text(
                'Aucune demande enregistrée.',
                style: TextStyle(fontSize: 13, color: AppColors.text2),
              ),
            ),
          )
        else
          ...notifier.demandes.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LeaveTile(item: item),
            ),
          ),
      ],
    );
  }

  Widget _buildRhContent(BuildContext context, CongeNotifier notifier) {
    final pendingRequests =
        notifier.demandes.where((item) => item.statut == 'EN_ATTENTE').toList();
    final allRequests =
        notifier.demandes.where((item) => item.statut != 'EN_ATTENTE').toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const GrhPageHeader(
          title: 'Demandes en attente',
          subtitle:
              'Validation rapide avec vision claire des collaborateurs et des périodes demandées.',
        ),
        const SizedBox(height: 20),
        if (pendingRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Center(
              child: Text(
                'Aucune demande en attente.',
                style: TextStyle(fontSize: 13, color: AppColors.text2),
              ),
            ),
          )
        else
          ...pendingRequests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _RhRequestCard(
                request: request,
                onApprove: () => ConfirmDialog.show(
                  context,
                  title: 'Approuver cette demande ?',
                  message: 'La demande sera validée immédiatement.',
                  type: 'success',
                  onConfirm: () =>
                      ref.read(congeNotifierProvider).approve(request.id),
                ),
                onReject: () => _showRejectDialog(context, request),
              ),
            ),
          ),
        if (allRequests.isNotEmpty) ...[
          const SizedBox(height: 28),
          const GrhPageHeader(
            title: 'Historique',
            subtitle: 'Demandes traitées.',
          ),
          const SizedBox(height: 16),
          ...allRequests.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LeaveTile(item: item),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showRejectDialog(BuildContext context, Conge request) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Refuser la demande',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text1,
          ),
        ),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Commentaire'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.text2),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(congeNotifierProvider).reject(
                    request.id,
                    commentaire: controller.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }
}

// ── Sélecteur de type de congé (chips visuels) ───────────────────────────────
class _CongeTypeSelector extends StatelessWidget {
  const _CongeTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label, icon) in _congeTypes)
          _CongeTypeChip(
            value: value,
            label: label,
            icon: icon,
            isSelected: selected == value,
            onTap: () => onChanged(value),
          ),
      ],
    );
  }
}

class _CongeTypeChip extends StatelessWidget {
  const _CongeTypeChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.text2,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sélecteur de plage de dates ──────────────────────────────────────────────
class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({required this.range, required this.onTap});

  final DateTimeRange? range;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasRange = range != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: hasRange
              ? AppColors.primary.withOpacity(0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasRange ? AppColors.primary.withOpacity(0.3) : AppColors.border,
            width: hasRange ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_outlined,
              size: 18,
              color:
                  hasRange ? AppColors.primary : AppColors.text2,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: hasRange
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Période sélectionnée',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppFormatters.shortDate(range!.start)}  →  ${AppFormatters.shortDate(range!.end)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text1,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Sélectionner les dates de début et fin',
                      style: TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
            ),
            if (hasRange) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${range!.duration.inDays + 1} j',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ] else
              const Icon(Icons.chevron_right, size: 18, color: AppColors.text2),
          ],
        ),
      ),
    );
  }
}

// ── Carte de solde de congé ──────────────────────────────────────────────────
class _SoldeCard extends StatelessWidget {
  const _SoldeCard({required this.solde, required this.selectedDays});

  final double solde;
  final int selectedDays;

  @override
  Widget build(BuildContext context) {
    final remaining = solde - selectedDays;
    final isOverdrawn = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOverdrawn
            ? AppColors.error.withOpacity(0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdrawn
              ? AppColors.error.withOpacity(0.3)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isOverdrawn ? AppColors.error : AppColors.primary)
                  .withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.balance_outlined,
              color: isOverdrawn ? AppColors.error : AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solde disponible : ${solde.toStringAsFixed(0)} jours',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1,
                  ),
                ),
                if (selectedDays > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    isOverdrawn
                        ? 'Dépassement de ${(-remaining).toStringAsFixed(0)} jours'
                        : 'Solde après demande : ${remaining.toStringAsFixed(0)} jours',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdrawn ? AppColors.error : AppColors.text2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (selectedDays > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isOverdrawn ? AppColors.error : AppColors.accent)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$selectedDays j demandés',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOverdrawn ? AppColors.error : AppColors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Carte RH (approbation/rejet) ─────────────────────────────────────────────
class _RhRequestCard extends StatelessWidget {
  const _RhRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final Conge request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // En-tête avec info employé
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                EmployeeAvatar(name: request.nomEmploye ?? 'Employé'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.nomEmploye ?? 'Employé',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        request.typeConge,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: '${request.nombreJours} j', type: 'pending'),
              ],
            ),
          ),

          // Détail période
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border.symmetric(
                horizontal: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_outlined,
                    size: 15, color: AppColors.text2),
                const SizedBox(width: 8),
                Text(
                  '${AppFormatters.shortDate(request.dateDebut)}  →  ${AppFormatters.shortDate(request.dateFin)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.text1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Boutons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      label: const Text('Approuver'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(
                            color: AppColors.error, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      label: const Text('Refuser'),
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

// ── Tuile historique ─────────────────────────────────────────────────────────
class _LeaveTile extends StatelessWidget {
  const _LeaveTile({required this.item});

  final Conge item;

  @override
  Widget build(BuildContext context) {
    final statusType = _statusType(item.statut);
    final statusColor = statusType == 'active'
        ? AppColors.success
        : statusType == 'rejected'
            ? AppColors.error
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusType == 'active'
                  ? Icons.task_alt_rounded
                  : statusType == 'rejected'
                      ? Icons.cancel_outlined
                      : Icons.hourglass_top_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.typeConge,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${AppFormatters.shortDate(item.dateDebut)} → ${AppFormatters.shortDate(item.dateFin)} • ${item.nombreJours} jours',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: _statusLabel(item.statut), type: statusType),
        ],
      ),
    );
  }
}

String _statusType(String status) {
  switch (status) {
    case 'APPROUVE':
      return 'active';
    case 'REFUSE':
      return 'rejected';
    default:
      return 'pending';
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'APPROUVE':
      return 'Approuvé';
    case 'REFUSE':
      return 'Rejeté';
    default:
      return 'En attente';
  }
}
