import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _formKey = GlobalKey<FormState>();
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
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final content = isEmployee ? _buildEmployeeContent(context, notifier) : _buildRhContent(context, notifier);

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.conges,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: GrhAppBar(
          title: 'Congés',
          userName: auth.user?.fullName,
          onMenuTap: isWide ? null : () => Scaffold.of(context).openDrawer(),
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
    final selectedDays = _dateRange == null ? 0 : _dateRange!.duration.inDays + 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouvelle demande',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: _typeConge,
                      decoration: const InputDecoration(labelText: 'Type de congé'),
                      items: const [
                        DropdownMenuItem(value: 'Annuel', child: Text('Annuel')),
                        DropdownMenuItem(value: 'Maladie', child: Text('Maladie')),
                        DropdownMenuItem(value: 'Maternité', child: Text('Maternité')),
                        DropdownMenuItem(value: 'Sans Solde', child: Text('Sans Solde')),
                      ],
                      onChanged: (value) => setState(() => _typeConge = value ?? 'Annuel'),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: _dateRange,
                          locale: const Locale('fr', 'TG'),
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _motifController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Motif (optionnel)'),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.34),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.balance_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Solde restant: ${notifier.soldeRestant.toStringAsFixed(0)} jours'),
                            ),
                            Text('$selectedDays jours'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: notifier.isLoading
                            ? null
                            : () async {
                                if (_dateRange == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Veuillez choisir une période.')),
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
                                if (!mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Demande de congé soumise.')),
                                );
                              },
                        child: const Text('SOUMETTRE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Historique des demandes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...notifier.demandes.map(_LeaveTile.new),
        ],
      ),
    );
  }

  Widget _buildRhContent(BuildContext context, CongeNotifier notifier) {
    final pendingRequests = notifier.demandes.where((item) => item.statut == 'EN_ATTENTE').toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Demandes en attente',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        if (pendingRequests.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Aucune demande en attente.'),
            ),
          )
        else
          ...pendingRequests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
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
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${request.typeConge} • ${AppFormatters.shortDate(request.dateDebut)} → ${AppFormatters.shortDate(request.dateFin)}',
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(label: '${request.nombreJours} jours', type: 'info'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => ConfirmDialog.show(
                                context,
                                title: 'Approuver cette demande ?',
                                message: 'La demande sera validée immédiatement.',
                                type: 'success',
                                onConfirm: () => ref.read(congeNotifierProvider).approve(request.id),
                              ),
                              icon: const Icon(Icons.check_rounded),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              label: const Text('APPROUVER'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showRejectDialog(context, request),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('REFUSER'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showRejectDialog(BuildContext context, Conge request) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Refuser la demande'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Commentaire'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(congeNotifierProvider).reject(
                    request.id,
                    commentaire: controller.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

class _LeaveTile extends StatelessWidget {
  const _LeaveTile(this.request);

  final Conge request;

  @override
  Widget build(BuildContext context) {
    final type = request.statut == 'APPROUVE'
        ? 'success'
        : request.statut == 'EN_ATTENTE'
            ? 'warning'
            : 'error';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          title: Text(request.typeConge),
          subtitle: Text(
            '${AppFormatters.shortDate(request.dateDebut)} → ${AppFormatters.shortDate(request.dateFin)} • ${request.nombreJours} jours',
          ),
          trailing: StatusBadge(label: request.statut, type: type),
        ),
      ),
    );
  }
}
