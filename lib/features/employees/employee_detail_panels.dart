import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Documents du dossier du personnel
// ══════════════════════════════════════════════════════════════════════════════

class EmployeeDocument {
  const EmployeeDocument({
    required this.id,
    required this.nom,
    required this.type,
    required this.tailleKo,
    required this.url,
    this.date,
  });

  final int id;
  final String nom;
  final String type;
  final int tailleKo;
  final String url;
  final DateTime? date;

  bool get isImage => const ['JPG', 'JPEG', 'PNG'].contains(type.toUpperCase());

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) => EmployeeDocument(
        id: (json['id'] as num).toInt(),
        nom: json['nom'] as String? ?? 'Document',
        type: json['type'] as String? ?? '',
        tailleKo: (json['tailleKo'] as num?)?.toInt() ?? 0,
        url: json['url'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? ''),
      );
}

final employeeDocumentsProvider =
    FutureProvider.autoDispose.family<List<EmployeeDocument>, String>((ref, matricule) async {
  final resp = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/employees/$matricule/documents');
  final raw = resp.data?['items'] as List? ?? const [];
  return raw.whereType<Map<String, dynamic>>().map(EmployeeDocument.fromJson).toList();
});

bool _isRh(Utilisateur? user) =>
    user != null &&
    (const [UserRole.superAdmin, UserRole.admin, UserRole.hrAdmin, UserRole.rhManager].contains(user.role) ||
        user.hasPermission('MANAGE_EMPLOYEES'));

class EmployeeDocumentsPanel extends ConsumerStatefulWidget {
  const EmployeeDocumentsPanel({super.key, required this.matricule, this.compact = false});

  final String matricule;
  final bool compact;

  @override
  ConsumerState<EmployeeDocumentsPanel> createState() => _EmployeeDocumentsPanelState();
}

class _EmployeeDocumentsPanelState extends ConsumerState<EmployeeDocumentsPanel> {
  bool _uploading = false;

  Future<void> _upload() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'xls', 'xlsx'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return;
    if (file.size > 10 * 1024 * 1024) {
      _snack('Le fichier ne doit pas dépasser 10 Mo.', error: true);
      return;
    }
    if (!mounted) return;
    final nom = await _askName(file.name);
    if (nom == null) return;

    setState(() => _uploading = true);
    try {
      await ref.read(apiServiceProvider).postFormData<Map<String, dynamic>>(
            '/employees/${widget.matricule}/documents',
            formData: FormData.fromMap({
              'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
              'nom': nom,
            }),
          );
      ref.invalidate(employeeDocumentsProvider(widget.matricule));
      _snack('Document ajouté.');
    } catch (e) {
      _snack(ApiService.messageOf(e, "Échec de l'envoi du document."), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String?> _askName(String defaultName) async {
    final ctrl = TextEditingController(text: defaultName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nom du document'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Libellé')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Envoyer')),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _download(EmployeeDocument doc) async {
    try {
      final path = await ref.read(apiServiceProvider).downloadFile(doc.url, doc.nom);
      _snack(path != null ? 'Document téléchargé.' : 'Fichier vide.');
    } catch (e) {
      _snack(ApiService.messageOf(e, 'Téléchargement impossible.'), error: true);
    }
  }

  Future<void> _delete(EmployeeDocument doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le document ?'),
        content: Text('« ${doc.nom} » sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(apiServiceProvider).delete<void>('/documents/${doc.id}');
      ref.invalidate(employeeDocumentsProvider(widget.matricule));
      _snack('Document supprimé.');
    } catch (e) {
      _snack(ApiService.messageOf(e, 'Suppression impossible.'), error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? AppColors.error : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(employeeDocumentsProvider(widget.matricule));
    final canDelete = _isRh(ref.watch(authNotifierProvider).user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text("Documents de l'employé",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text1)),
            ),
            ElevatedButton.icon(
              onPressed: _uploading ? null : _upload,
              icon: _uploading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add, size: 14),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        docs.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(ApiService.messageOf(e, 'Impossible de charger les documents.'),
              style: const TextStyle(color: AppColors.error, fontSize: 12)),
          data: (items) => items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Aucun document dans ce dossier.',
                      style: TextStyle(fontSize: 12, color: AppColors.text2)),
                )
              : Column(
                  children: [
                    for (final doc in widget.compact ? items.take(5) : items)
                      _DocumentTile(
                        doc: doc,
                        onDownload: () => _download(doc),
                        onDelete: canDelete ? () => _delete(doc) : null,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc, required this.onDownload, this.onDelete});

  final EmployeeDocument doc;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final size = doc.tailleKo >= 1024 ? '${(doc.tailleKo / 1024).toStringAsFixed(1)} Mo' : '${doc.tailleKo} Ko';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: doc.isImage ? AppColors.primarySoft : AppColors.badgeDangerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                doc.type.isEmpty ? 'DOC' : doc.type.toUpperCase(),
                style: TextStyle(
                  color: doc.isImage ? AppColors.primary : AppColors.badgeDangerFg,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.nom,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('$size${doc.date != null ? ' • ${AppFormatters.shortDate(doc.date)}' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.text2)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Télécharger',
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined, size: 18, color: AppColors.text2),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Compétences
// ══════════════════════════════════════════════════════════════════════════════

final employeeCompetencesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, matricule) async {
  final resp = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/employees/$matricule/competences');
  final raw = resp.data?['items'] as List? ?? const [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

class EmployeeCompetencesPanel extends ConsumerWidget {
  const EmployeeCompetencesPanel({super.key, required this.matricule});

  final String matricule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(employeeCompetencesProvider(matricule)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(ApiService.messageOf(e, 'Impossible de charger les compétences.'),
              style: const TextStyle(color: AppColors.error, fontSize: 12)),
          data: (items) {
            if (items.isEmpty) {
              return const Text('Aucune compétence renseignée.',
                  style: TextStyle(fontSize: 12, color: AppColors.text2));
            }
            return Column(
              children: [
                for (final c in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c['libelle'] as String? ?? '',
                                style: const TextStyle(fontSize: 13, color: AppColors.text1)),
                            Text('${(c['niveau'] as num?)?.toInt() ?? 0} / 5',
                                style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (((c['niveau'] as num?)?.toDouble() ?? 0) / 5).clamp(0, 1),
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Contrats : historique et création
// ══════════════════════════════════════════════════════════════════════════════

final employeeContratsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, matricule) async {
  final resp = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/employees/$matricule/contrats');
  final raw = resp.data?['items'] as List? ?? const [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

class EmployeeContratsPanel extends ConsumerWidget {
  const EmployeeContratsPanel({super.key, required this.matricule, this.onChanged});

  final String matricule;

  /// Appelé après création d'un contrat (la fiche employé est mise à jour côté serveur).
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = _isRh(ref.watch(authNotifierProvider).user);
    final fmt = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Historique des contrats',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text1)),
            ),
            if (canManage)
              ElevatedButton.icon(
                onPressed: () async {
                  final created = await showDialog<bool>(
                    context: context,
                    builder: (_) => _NewContratDialog(matricule: matricule),
                  );
                  if (created == true) {
                    ref.invalidate(employeeContratsProvider(matricule));
                    onChanged?.call();
                  }
                },
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Nouveau contrat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ref.watch(employeeContratsProvider(matricule)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(ApiService.messageOf(e, 'Historique des contrats indisponible.'),
                  style: const TextStyle(color: AppColors.text2, fontSize: 12)),
              data: (items) => items.isEmpty
                  ? const Text('Aucun contrat enregistré.', style: TextStyle(fontSize: 12, color: AppColors.text2))
                  : Column(
                      children: [
                        for (final c in items)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                            title: Text(
                                '${c['typeContrat'] ?? ''} • ${AppFormatters.currency(((c['salaireBrut'] as num?) ?? 0).toDouble())}'),
                            subtitle: Text(
                              'Du ${_d(fmt, c['dateDebut'])}${c['dateFin'] != null ? ' au ${_d(fmt, c['dateFin'])}' : ' (durée indéterminée)'}'
                              '${c['posteIntitule'] != null ? ' • ${c['posteIntitule']}' : ''}',
                            ),
                            trailing: Chip(
                              label: Text(c['statut'] as String? ?? '', style: const TextStyle(fontSize: 11)),
                              backgroundColor:
                                  c['statut'] == 'ACTIF' ? AppColors.badgeSuccessBg : AppColors.surface,
                            ),
                          ),
                      ],
                    ),
            ),
      ],
    );
  }

  static String _d(DateFormat fmt, Object? iso) {
    final date = DateTime.tryParse(iso?.toString() ?? '');
    return date == null ? '—' : fmt.format(date);
  }
}

class _NewContratDialog extends ConsumerStatefulWidget {
  const _NewContratDialog({required this.matricule});

  final String matricule;

  @override
  ConsumerState<_NewContratDialog> createState() => _NewContratDialogState();
}

class _NewContratDialogState extends ConsumerState<_NewContratDialog> {
  final _formKey = GlobalKey<FormState>();
  final _salaire = TextEditingController();
  String _type = 'CDI';
  DateTime _debut = DateTime.now();
  DateTime? _fin;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _salaire.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _debut : (_fin ?? _debut.add(const Duration(days: 180))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => start ? _debut = picked : _fin = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_type != 'CDI' && _fin == null) {
      setState(() => _error = 'La date de fin est obligatoire pour un $_type.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    String iso(DateTime d) => d.toIso8601String().substring(0, 10);
    try {
      await ref.read(apiServiceProvider).post<Map<String, dynamic>>(
        '/employees/${widget.matricule}/contrats',
        data: {
          'typeContrat': _type,
          'dateDebut': iso(_debut),
          if (_fin != null) 'dateFin': iso(_fin!),
          'salaireBrut': double.parse(_salaire.text.trim().replaceAll(' ', '')),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = ApiService.messageOf(e, 'Création du contrat impossible.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return AlertDialog(
      title: const Text('Nouveau contrat'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type de contrat'),
              items: const [
                DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                DropdownMenuItem(value: 'STAGE', child: Text('Stage')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'CDI'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de début'),
              subtitle: Text(fmt.format(_debut)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pick(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_type == 'CDI' ? 'Date de fin (facultative)' : 'Date de fin *'),
              subtitle: Text(_fin == null ? 'Non définie' : fmt.format(_fin!)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pick(false),
            ),
            TextFormField(
              controller: _salaire,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Salaire brut mensuel (FCFA)'),
              validator: (v) {
                final value = double.tryParse((v ?? '').trim().replaceAll(' ', ''));
                if (value == null) return 'Montant invalide';
                if (value < 0) return 'Le montant doit être positif';
                return null;
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Le contrat actif précédent sera clôturé et la fiche employé mise à jour.',
                style: TextStyle(fontSize: 11, color: AppColors.text2),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Créer')),
      ],
    );
  }
}
