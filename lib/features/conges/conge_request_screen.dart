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
        const GrhPageHeader(
          title: 'Demande de congé',
          subtitle:
              'Soumission simple, suivi des statuts et visualisation du solde restant.',
        ),
        const SizedBox(height: 20),
        GrhSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _typeConge,
                decoration: const InputDecoration(labelText: 'Type de congé'),
                items: const [
                  DropdownMenuItem(
                      value: 'Annuel', child: Text('Congé annuel')),
                  DropdownMenuItem(
                      value: 'Maladie', child: Text('Congé maladie')),
                  DropdownMenuItem(
                      value: 'Maternite', child: Text('Congé maternité')),
                  DropdownMenuItem(
                      value: 'Sans Solde', child: Text('Sans solde')),
                ],
                onChanged: (value) =>
                    setState(() => _typeConge = value ?? 'Annuel'),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
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
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Période'),
                  child: Text(
                    _dateRange == null
                        ? 'Choisir les dates'
                        : '${AppFormatters.shortDate(_dateRange!.start)} → ${AppFormatters.shortDate(_dateRange!.end)}',
                    style: TextStyle(
                      color: _dateRange == null
                          ? AppColors.textHint
                          : AppColors.text1,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _motifController,
                minLines: 3,
                maxLines: 4,
                decoration:
                    const InputDecoration(labelText: 'Motif (optionnel)'),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.balance_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Solde restant : ${notifier.soldeRestant.toStringAsFixed(0)} jours',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (selectedDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$selectedDays j',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                                  content:
                                      Text('Veuillez choisir une période.')),
                            );
                            return;
                          }
                          await ref.read(congeNotifierProvider).submitRequest(
                                typeConge: _typeConge,
                                dateDebut: _dateRange!.start,
                                dateFin: _dateRange!.end,
                                motif: _motifController.text.trim().isEmpty
                                    ? null
                                    : _motifController.text.trim(),
                              );
                          _motifController.clear();
                          setState(() => _dateRange = null);
                        },
                  child: notifier.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Soumettre la demande'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
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
                      '${request.typeConge} • ${AppFormatters.shortDate(request.dateDebut)} → ${AppFormatters.shortDate(request.dateFin)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: '${request.nombreJours} j',
                type: 'pending',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
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
                      side: const BorderSide(color: AppColors.error, width: 1),
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
        ],
      ),
    );
  }
}

class _LeaveTile extends StatelessWidget {
  const _LeaveTile({required this.item});

  final Conge item;

  @override
  Widget build(BuildContext context) {
    final statusType = _statusType(item.statut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: AppColors.primary,
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
