import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/frais_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

/// Notes de frais : l'employé déclare ses dépenses ; RH et paie les traitent.
/// « Remboursée » est une déclaration manuelle : l'application n'effectue aucun paiement.
class NotesFraisScreen extends ConsumerStatefulWidget {
  const NotesFraisScreen({super.key});

  @override
  ConsumerState<NotesFraisScreen> createState() => _NotesFraisScreenState();
}

class _NotesFraisScreenState extends ConsumerState<NotesFraisScreen> {
  String? _statut = 'SOUMISE';

  bool _isManager(UserRole? role) =>
      role != null && (role.isHrFamily || role == UserRole.payrollOfficer);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final manager = _isManager(auth.role);

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(child: GrhSidebar(currentRoute: AppRoutes.notesFrais, role: auth.role!, isDrawer: true)),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: manager ? 'Notes de frais' : 'Mes notes de frais',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      floatingActionButton: manager
          ? null
          : FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Déclarer', style: TextStyle(color: Colors.white)),
            ),
      body: Row(
        children: [
          if (isWide && auth.role != null) GrhSidebar(currentRoute: AppRoutes.notesFrais, role: auth.role!),
          Expanded(child: manager ? _managerView() : _employeeView()),
        ],
      ),
    );
  }

  // ── Vue employé ────────────────────────────────────────────────────────────

  Widget _employeeView() {
    final async = ref.watch(mesNotesFraisProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _message(ApiService.messageOf(e, 'Impossible de charger vos notes de frais.')),
      data: (items) => items.isEmpty
          ? _message('Aucune note de frais. Utilisez « Déclarer » pour en ajouter une.')
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(mesNotesFraisProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _NoteCard(note: items[i]),
              ),
            ),
    );
  }

  Future<void> _openForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _NoteFraisForm(),
    );
    if (created == true) {
      ref.invalidate(mesNotesFraisProvider);
      _snack('Note de frais soumise.');
    }
  }

  // ── Vue RH / paie ──────────────────────────────────────────────────────────

  Widget _managerView() {
    final async = ref.watch(toutesNotesFraisProvider(_statut));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(label: const Text('Toutes'), selected: _statut == null, onSelected: (_) => setState(() => _statut = null)),
              for (final e in statutsFrais.entries)
                ChoiceChip(label: Text(e.value), selected: _statut == e.key, onSelected: (_) => setState(() => _statut = e.key)),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _message(ApiService.messageOf(e, 'Impossible de charger les notes de frais.')),
            data: (items) => items.isEmpty
                ? _message('Aucune note de frais pour ce filtre.')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _NoteCard(
                      note: items[i],
                      showEmployee: true,
                      onAction: (action) => _act(items[i], action),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _act(Map<String, dynamic> note, String action) async {
    final id = (note['id'] as num).toInt();
    final api = ref.read(apiServiceProvider);
    try {
      if (action == 'approve') {
        await api.post<Map<String, dynamic>>('/notes-frais/$id/approve');
      } else if (action == 'reject') {
        final motif = await _ask('Motif du refus', 'Motif');
        if (motif == null) return;
        await api.post<Map<String, dynamic>>('/notes-frais/$id/reject', data: {'commentaire': motif});
      } else if (action == 'rembourser') {
        final ref0 = await _ask(
          'Déclarer le remboursement',
          'Référence (virement, mobile money, caisse)',
          help: "Le paiement doit avoir été effectué en dehors de l'application.",
        );
        if (ref0 == null) return;
        await api.post<Map<String, dynamic>>('/notes-frais/$id/remboursement', data: {'reference': ref0});
      }
      ref.invalidate(toutesNotesFraisProvider(_statut));
      _snack('Note de frais mise à jour.');
    } catch (e) {
      _snack(ApiService.messageOf(e, "L'action a échoué."), error: true);
    }
  }

  Future<String?> _ask(String title, String label, {String? help}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (help != null) ...[
              Text(help, style: const TextStyle(fontSize: 12, color: AppColors.text2)),
              const SizedBox(height: 8),
            ],
            TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(labelText: label)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.text2)),
        ),
      );

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red.shade700 : null),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, this.showEmployee = false, this.onAction});

  final Map<String, dynamic> note;
  final bool showEmployee;
  final void Function(String action)? onAction;

  @override
  Widget build(BuildContext context) {
    final statut = note['statut'] as String? ?? '';
    final montant = note['montant'];
    final categorie = categoriesFrais[note['categorie']] ?? note['categorie'];
    return GrhSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$montant ${note['devise'] ?? 'XOF'} · $categorie',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              StatusBadge(label: statutsFrais[statut] ?? statut),
            ],
          ),
          const SizedBox(height: 4),
          if (showEmployee)
            Text('${note['employe']} (${note['matricule']})', style: const TextStyle(color: AppColors.text2, fontSize: 12)),
          Text('Dépense du ${note['dateDepense']}', style: const TextStyle(color: AppColors.text2, fontSize: 12)),
          const SizedBox(height: 6),
          Text(note['description'] as String? ?? ''),
          if (note['justificatif'] == true)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(children: [
                Icon(Icons.attach_file, size: 14, color: AppColors.text2),
                SizedBox(width: 4),
                Text('Justificatif joint', style: TextStyle(fontSize: 12, color: AppColors.text2)),
              ]),
            ),
          if (note['commentaire'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Motif : ${note['commentaire']}', style: const TextStyle(fontSize: 12, color: Colors.red)),
            ),
          if (note['referenceRemboursement'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Remboursement déclaré : ${note['referenceRemboursement']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.text2)),
            ),
          if (onAction != null && (statut == 'SOUMISE' || statut == 'APPROUVEE'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (statut == 'SOUMISE') ...[
                    OutlinedButton(onPressed: () => onAction!('reject'), child: const Text('Refuser')),
                    OutlinedButton(onPressed: () => onAction!('approve'), child: const Text('Approuver')),
                  ],
                  if (statut == 'APPROUVEE')
                    OutlinedButton(onPressed: () => onAction!('rembourser'), child: const Text('Déclarer remboursée')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteFraisForm extends ConsumerStatefulWidget {
  const _NoteFraisForm();

  @override
  ConsumerState<_NoteFraisForm> createState() => _NoteFraisFormState();
}

class _NoteFraisFormState extends ConsumerState<_NoteFraisForm> {
  final _montant = TextEditingController();
  final _description = TextEditingController();
  String _categorie = 'TRANSPORT';
  DateTime _date = DateTime.now();
  PlatformFile? _file;
  bool _sending = false;
  String? _error;

  Future<void> _pick() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    final f = picked?.files.single;
    if (f == null || f.bytes == null) return;
    if (f.size > 5 * 1024 * 1024) {
      setState(() => _error = 'Le justificatif ne doit pas dépasser 5 Mo.');
      return;
    }
    setState(() {
      _file = f;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final montant = double.tryParse(_montant.text.replaceAll(',', '.').replaceAll(' ', ''));
    if (montant == null || montant <= 0) {
      setState(() => _error = 'Montant invalide.');
      return;
    }
    if (_description.text.trim().isEmpty) {
      setState(() => _error = 'La description est obligatoire.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final d = _date;
      final data = <String, dynamic>{
        'dateDepense': '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'categorie': _categorie,
        'montant': montant.toString(),
        'description': _description.text.trim(),
        if (_file != null) 'justificatif': MultipartFile.fromBytes(_file!.bytes!, filename: _file!.name),
      };
      await ref.read(apiServiceProvider).postFormData<Map<String, dynamic>>('/notes-frais', formData: FormData.fromMap(data));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = ApiService.messageOf(e, "L'envoi a échoué."));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nouvelle note de frais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categorie,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: [
                for (final e in categoriesFrais.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _categorie = v ?? _categorie),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montant,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Montant (XOF)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de la dépense'),
              subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.attach_file),
              label: Text(_file == null ? 'Joindre un justificatif (PDF, PNG, JPEG)' : _file!.name),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Soumettre'),
            ),
          ],
        ),
      ),
    );
  }
}
