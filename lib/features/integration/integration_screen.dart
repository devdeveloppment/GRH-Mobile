import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_page_scaffold.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';

final _processusProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final r = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/integration/processus');
  return (r.data?['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
});

final _tachesProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, matricule) async {
  final r = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/employees/$matricule/integration');
  return r.data ?? {};
});

String _libelleType(String? t) => t == 'DEPART' ? 'Départ' : 'Arrivée';

/// Arrivées et départs : listes de tâches par employé, responsables, échéances, clôture.
class IntegrationScreen extends ConsumerStatefulWidget {
  const IntegrationScreen({super.key});

  @override
  ConsumerState<IntegrationScreen> createState() => _IntegrationScreenState();
}

class _IntegrationScreenState extends ConsumerState<IntegrationScreen> {
  String _filtre = 'TOUS';

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(_processusProvider);
    return GrhPageScaffold(
      title: 'Arrivées et départs',
      route: AppRoutes.integration,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('nouveauProcessus'),
        backgroundColor: AppColors.accent,
        onPressed: () => _nouveauProcessus(context, ref),
        icon: const Icon(Icons.add_task),
        label: const Text('Nouveau processus'),
      ),
      body: GrhAsync<List<Map<String, dynamic>>>(
        value: value,
        onRetry: () => ref.invalidate(_processusProvider),
        data: (items) {
          final visibles = items.where((p) => _filtre == 'TOUS' || p['type'] == _filtre).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'TOUS', label: Text('Tous')),
                  ButtonSegment(value: 'ARRIVEE', label: Text('Arrivées')),
                  ButtonSegment(value: 'DEPART', label: Text('Départs')),
                ],
                selected: {_filtre},
                onSelectionChanged: (s) => setState(() => _filtre = s.first),
              ),
              const SizedBox(height: 12),
              if (visibles.isEmpty)
                const GrhSurfaceCard(
                  child: Text('Aucun processus. Créez une liste de tâches pour une arrivée ou un départ.'),
                ),
              for (final p in visibles) _ProcessusCard(processus: p),
            ],
          );
        },
      ),
    );
  }
}

class _ProcessusCard extends StatelessWidget {
  const _ProcessusCard({required this.processus});

  final Map<String, dynamic> processus;

  @override
  Widget build(BuildContext context) {
    final total = (processus['total'] as num?)?.toInt() ?? 0;
    final faites = (processus['faites'] as num?)?.toInt() ?? 0;
    final retard = (processus['enRetard'] as num?)?.toInt() ?? 0;
    final cloture = processus['cloture'] != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => _DetailProcessus(
            matricule: processus['matricule'] as String,
            type: processus['type'] as String,
            nom: '${processus['prenom']} ${processus['nom']}',
          ),
        )),
        child: GrhSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${processus['prenom']} ${processus['nom']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  GrhBadge(_libelleType(processus['type'] as String?)),
                  if (cloture) const GrhBadge('Clôturé', tone: GrhBadgeTone.success),
                  if (!cloture && retard > 0) GrhBadge('$retard en retard', tone: GrhBadgeTone.danger),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: total == 0 ? 0 : faites / total,
                backgroundColor: AppColors.border,
                color: cloture ? AppColors.success : AppColors.accent,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                '$faites / $total tâches · ${processus['matricule']}'
                '${processus['prochaineEcheance'] != null ? ' · prochaine échéance ${formatDate(processus['prochaineEcheance'] as String?)}' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _nouveauProcessus(BuildContext context, WidgetRef ref) async {
  final api = ref.read(apiServiceProvider);
  List<Map<String, dynamic>> employes;
  try {
    final r = await api.get<Map<String, dynamic>>('/employees', queryParameters: {'size': 500});
    employes = (r.data?['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
  } catch (e) {
    if (context.mounted) grhSnack(context, messageErreur(e, 'Liste des employés indisponible.'), error: true);
    return;
  }
  if (!context.mounted) return;
  String? matricule;
  String type = 'ARRIVEE';
  final echeance = TextEditingController(text: isoDate(DateTime.now().add(const Duration(days: 14))));
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Nouveau processus'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: matricule,
                decoration: const InputDecoration(labelText: 'Employé'),
                items: [
                  for (final e in employes)
                    DropdownMenuItem(
                      value: e['matricule'] as String,
                      child: Text('${e['prenom']} ${e['nom']} (${e['matricule']})', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => matricule = v),
              ),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'ARRIVEE', child: Text('Arrivée')),
                  DropdownMenuItem(value: 'DEPART', child: Text('Départ')),
                ],
                onChanged: (v) => setState(() => type = v ?? type),
              ),
              TextField(controller: echeance, decoration: const InputDecoration(labelText: 'Échéance (AAAA-MM-JJ)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: matricule == null ? null : () => Navigator.pop(ctx, true), child: const Text('Créer')),
        ],
      ),
    ),
  );
  if (ok != true || matricule == null || !context.mounted) return;
  try {
    await api.post<Map<String, dynamic>>('/employees/$matricule/integration/${type.toLowerCase()}',
        data: {'echeance': echeance.text.trim()});
    ref.invalidate(_processusProvider);
    if (context.mounted) grhSnack(context, 'Liste de tâches créée.');
  } catch (e) {
    if (context.mounted) grhSnack(context, messageErreur(e), error: true);
  }
}

// ── Détail d'un processus ───────────────────────────────────────────────────

class _DetailProcessus extends ConsumerWidget {
  const _DetailProcessus({required this.matricule, required this.type, required this.nom});

  final String matricule;
  final String type;
  final String nom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(_tachesProvider(matricule));
    void rafraichir() {
      ref.invalidate(_tachesProvider(matricule));
      ref.invalidate(_processusProvider);
    }

    return Scaffold(
      key: const Key('detailProcessus'),
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text('${_libelleType(type)} — $nom')),
      body: GrhAsync<Map<String, dynamic>>(
        value: value,
        onRetry: rafraichir,
        data: (data) {
          final taches = (data['items'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .where((t) => t['type'] == type)
              .toList();
          final clos = (data['clotures'] as Map?)?[type] as String?;
          final restantes = taches.where((t) => t['faite'] != true).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (clos != null)
                GrhBanner('Processus clôturé le ${formatDate(clos)}. Les tâches ne sont plus modifiables.',
                    icon: Icons.lock_outline),
              for (final t in taches) _TacheTile(tache: t, verrouille: clos != null, onChanged: rafraichir),
              const SizedBox(height: 12),
              if (clos == null) ...[
                OutlinedButton.icon(
                  onPressed: () => _ajouterTache(context, ref, matricule, type, rafraichir),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une tâche'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('cloturerProcessus'),
                  onPressed: restantes > 0 ? null : () => _cloturer(context, ref, matricule, type, rafraichir),
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(restantes > 0 ? 'Clôture possible après les $restantes tâche(s) restante(s)' : 'Clôturer'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TacheTile extends ConsumerWidget {
  const _TacheTile({required this.tache, required this.verrouille, required this.onChanged});

  final Map<String, dynamic> tache;
  final bool verrouille;
  final VoidCallback onChanged;

  Future<void> _maj(BuildContext context, WidgetRef ref, Map<String, dynamic> data) async {
    try {
      await ref.read(apiServiceProvider).put<Map<String, dynamic>>('/integration/taches/${tache['id']}', data: data);
      onChanged();
    } catch (e) {
      if (context.mounted) grhSnack(context, messageErreur(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final echeance = tache['echeance'] as String?;
    final enRetard = tache['faite'] != true && echeance != null && DateTime.parse(echeance).isBefore(DateTime.now());
    final details = [
      if (tache['responsable'] != null) 'Responsable : ${tache['responsable']}',
      'Échéance : ${formatDate(echeance)}',
      if (tache['faite'] == true && tache['faitePar'] != null) 'Faite par ${tache['faitePar']}',
      if (tache['commentaire'] != null) tache['commentaire'],
    ].join(' · ');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: enRetard ? AppColors.error : AppColors.border),
      ),
      child: CheckboxListTile(
        value: tache['faite'] == true,
        onChanged: verrouille ? null : (v) => _maj(context, ref, {'faite': v == true}),
        title: Text(tache['libelle']?.toString() ?? ''),
        subtitle: Text(details, style: TextStyle(fontSize: 12, color: enRetard ? AppColors.error : AppColors.text2)),
        controlAffinity: ListTileControlAffinity.leading,
        secondary: verrouille
            ? null
            : IconButton(
                tooltip: 'Responsable, échéance, commentaire',
                icon: const Icon(Icons.edit_note),
                onPressed: () => _editer(context, ref),
              ),
      ),
    );
  }

  Future<void> _editer(BuildContext context, WidgetRef ref) async {
    final responsable = TextEditingController(text: tache['responsable']?.toString() ?? '');
    final echeance = TextEditingController(text: tache['echeance']?.toString() ?? '');
    final commentaire = TextEditingController(text: tache['commentaire']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tache['libelle']?.toString() ?? 'Tâche'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: responsable, decoration: const InputDecoration(labelText: 'Responsable')),
              TextField(controller: echeance, decoration: const InputDecoration(labelText: 'Échéance (AAAA-MM-JJ)')),
              TextField(controller: commentaire, maxLines: 2, decoration: const InputDecoration(labelText: 'Commentaire')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await _maj(context, ref, {
        'responsable': responsable.text.trim(),
        'echeance': echeance.text.trim(),
        'commentaire': commentaire.text.trim(),
      });
    }
  }
}

Future<void> _ajouterTache(
    BuildContext context, WidgetRef ref, String matricule, String type, VoidCallback onDone) async {
  final libelle = TextEditingController();
  final responsable = TextEditingController();
  final echeance = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nouvelle tâche'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: libelle, decoration: const InputDecoration(labelText: 'Libellé')),
            TextField(controller: responsable, decoration: const InputDecoration(labelText: 'Responsable')),
            TextField(controller: echeance, decoration: const InputDecoration(labelText: 'Échéance (AAAA-MM-JJ)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajouter')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(apiServiceProvider).post<Map<String, dynamic>>(
      '/employees/$matricule/integration/${type.toLowerCase()}/taches',
      data: {
        'libelle': libelle.text.trim(),
        if (responsable.text.trim().isNotEmpty) 'responsable': responsable.text.trim(),
        if (echeance.text.trim().isNotEmpty) 'echeance': echeance.text.trim(),
      },
    );
    onDone();
  } catch (e) {
    if (context.mounted) grhSnack(context, messageErreur(e), error: true);
  }
}

Future<void> _cloturer(
    BuildContext context, WidgetRef ref, String matricule, String type, VoidCallback onDone) async {
  final commentaire = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Clôturer le processus'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: commentaire,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Commentaire de clôture (facultatif)'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clôturer')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(apiServiceProvider).post<Map<String, dynamic>>(
        '/employees/$matricule/integration/${type.toLowerCase()}/cloture',
        data: {'commentaire': commentaire.text.trim()});
    onDone();
    if (context.mounted) grhSnack(context, 'Processus clôturé.');
  } catch (e) {
    if (context.mounted) grhSnack(context, messageErreur(e), error: true);
  }
}
