import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_page_scaffold.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';

final _rubriquesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final r = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/paie/rubriques');
  return (r.data?['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
});

final _parametresProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final r = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/paie/parametres');
  return (r.data?['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
});

const _typesRubrique = {
  'GAIN': 'Gain',
  'COTISATION_SALARIALE': 'Cotisation salariale',
  'IMPOT': 'Impôt',
  'RETENUE': 'Retenue',
};

const _qualites = {
  'EXPERT_COMPTABLE': 'Expert-comptable',
  'JURISTE': 'Juriste',
  'AUTRE': 'Autre',
};

/// Configuration de la paie : rubriques (formules) et paramètres datés avec circuit de validation.
/// Aucun taux n'est fourni : tant qu'un paramètre n'est pas validé, il reste une hypothèse de simulation.
class PaieConfigurationScreen extends ConsumerWidget {
  const PaieConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: GrhPageScaffold(
        title: 'Configuration de la paie',
        route: AppRoutes.paieConfiguration,
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GrhBanner(
                "Aucun taux légal n'est fourni par l'application. Un paramètre n'est pris en compte comme règle "
                "validée qu'après validation par un expert-comptable ou un juriste, sur la base d'une source officielle. "
                'Tant que ce n\'est pas le cas, les bulletins portent la mention « SIMULATION ».',
                icon: Icons.gavel_outlined,
              ),
            ),
            const TabBar(
              labelColor: AppColors.primary,
              indicatorColor: AppColors.accent,
              tabs: [Tab(text: 'Paramètres'), Tab(text: 'Rubriques')],
            ),
            Expanded(
              child: TabBarView(children: [_ParametresTab(), _RubriquesTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Paramètres ──────────────────────────────────────────────────────────────

class _ParametresTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(_parametresProvider);
    return GrhAsync<List<Map<String, dynamic>>>(
      value: value,
      onRetry: () => ref.invalidate(_parametresProvider),
      data: (items) {
        // Historique : versions regroupées par code, de la plus récente à la plus ancienne.
        final parCode = <String, List<Map<String, dynamic>>>{};
        for (final p in items) {
          parCode.putIfAbsent(p['code'] as String, () => []).add(p);
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('nouveauParametre'),
                onPressed: () => _editerParametre(context, ref, null),
                icon: const Icon(Icons.add),
                label: const Text('Nouveau paramètre'),
              ),
            ),
            const SizedBox(height: 12),
            if (parCode.isEmpty)
              const GrhSurfaceCard(
                child: Text('Aucun paramètre. Ajoutez les valeurs fournies par votre expert-comptable, '
                    'avec leur source officielle.'),
              ),
            for (final e in parCode.entries) ...[
              _ParametreCard(code: e.key, versions: e.value),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

(String, GrhBadgeTone) _statut(Map<String, dynamic> p) => switch (p['statut']) {
      'VALIDE' => ('Validé', GrhBadgeTone.success),
      'SOUMIS' => ('En attente de validation', GrhBadgeTone.warning),
      _ => ('Brouillon — simulation', GrhBadgeTone.neutral),
    };

class _ParametreCard extends ConsumerWidget {
  const _ParametreCard({required this.code, required this.versions});

  final String code;
  final List<Map<String, dynamic>> versions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courante = versions.first;
    return GrhSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(courante['libelle']?.toString() ?? code,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(code, style: const TextStyle(color: AppColors.text2, fontSize: 12)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _editerParametre(context, ref, courante),
                icon: const Icon(Icons.history_edu_outlined, size: 18),
                label: const Text('Nouvelle version'),
              ),
            ],
          ),
          const Divider(),
          for (final v in versions) _VersionRow(version: v),
        ],
      ),
    );
  }
}

class _VersionRow extends ConsumerWidget {
  const _VersionRow({required this.version});

  final Map<String, dynamic> version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, tone) = _statut(version);
    final statut = version['statut'];
    final fin = version['dateFin'] != null ? ' au ${formatDate(version['dateFin'] as String?)}' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${version['valeur']}', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('du ${formatDate(version['dateDebut'] as String?)}$fin',
              style: const TextStyle(color: AppColors.text2)),
          GrhBadge(label, tone: tone),
          if (version['source'] != null)
            Text('Source : ${version['source']}', style: const TextStyle(fontSize: 12, color: AppColors.text2)),
          if (statut == 'VALIDE')
            Text(
              'Validé par ${version['validePar']} (${_qualites[version['qualiteValidateur']] ?? '—'}) '
              'le ${formatDate(version['dateValidation'] as String?)}',
              style: const TextStyle(fontSize: 12, color: AppColors.text2),
            ),
          if (statut == 'BROUILLON' || statut == null)
            OutlinedButton(onPressed: () => _soumettre(context, ref, version), child: const Text('Soumettre à validation')),
          if (statut == 'SOUMIS')
            OutlinedButton(
                onPressed: () => _valider(context, ref, version), child: const Text('Enregistrer la validation')),
        ],
      ),
    );
  }
}

Future<void> _editerParametre(BuildContext context, WidgetRef ref, Map<String, dynamic>? base) async {
  final code = TextEditingController(text: base?['code']?.toString() ?? '');
  final libelle = TextEditingController(text: base?['libelle']?.toString() ?? '');
  final valeur = TextEditingController();
  final debut = TextEditingController(text: isoDate(DateTime.now()));
  final fin = TextEditingController();
  final source = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(base == null ? 'Nouveau paramètre' : 'Nouvelle version de ${base['code']}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: code,
                enabled: base == null,
                decoration: const InputDecoration(labelText: 'Code (MAJUSCULES, ex. TAUX_RETENUE_X)'),
              ),
              TextField(controller: libelle, decoration: const InputDecoration(labelText: 'Libellé')),
              TextField(
                controller: valeur,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valeur (taux en décimal : 0.05 = 5 %)'),
              ),
              TextField(controller: debut, decoration: const InputDecoration(labelText: "Date d'application (AAAA-MM-JJ)")),
              TextField(controller: fin, decoration: const InputDecoration(labelText: 'Date de fin (facultative)')),
              TextField(
                controller: source,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Source officielle (texte, article, date)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer en brouillon')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(apiServiceProvider).post<Map<String, dynamic>>('/paie/parametres', data: {
      'code': code.text.trim().toUpperCase(),
      'libelle': libelle.text.trim(),
      'valeur': valeur.text.trim(),
      'dateDebut': debut.text.trim(),
      if (fin.text.trim().isNotEmpty) 'dateFin': fin.text.trim(),
      if (source.text.trim().isNotEmpty) 'source': source.text.trim(),
    });
    ref.invalidate(_parametresProvider);
    if (context.mounted) grhSnack(context, 'Paramètre enregistré en brouillon (non validé).');
  } catch (e) {
    if (context.mounted) grhSnack(context, messageErreur(e), error: true);
  }
}

Future<void> _soumettre(BuildContext context, WidgetRef ref, Map<String, dynamic> p) async {
  final source = TextEditingController(text: p['source']?.toString() ?? '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Soumettre à validation'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: source,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Source officielle (obligatoire)'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Soumettre')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(apiServiceProvider).put<Map<String, dynamic>>('/paie/parametres/${p['id']}/soumission',
        data: {'source': source.text.trim()});
    ref.invalidate(_parametresProvider);
    if (context.mounted) grhSnack(context, 'Paramètre soumis. Une autre personne doit enregistrer la validation.');
  } catch (e) {
    if (context.mounted) grhSnack(context, messageErreur(e), error: true);
  }
}

Future<void> _valider(BuildContext context, WidgetRef ref, Map<String, dynamic> p) async {
  final validePar = TextEditingController();
  final source = TextEditingController(text: p['source']?.toString() ?? '');
  String qualite = 'EXPERT_COMPTABLE';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Enregistrer la validation'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enregistrez uniquement une validation réellement donnée par un professionnel qualifié. "
                "L'application trace cette déclaration ; elle ne certifie pas la conformité.",
                style: TextStyle(fontSize: 13, color: AppColors.text2),
              ),
              TextField(controller: validePar, decoration: const InputDecoration(labelText: 'Nom du validateur')),
              DropdownButtonFormField<String>(
                initialValue: qualite,
                decoration: const InputDecoration(labelText: 'Qualité'),
                items: [for (final q in _qualites.entries) DropdownMenuItem(value: q.key, child: Text(q.value))],
                onChanged: (v) => setState(() => qualite = v ?? qualite),
              ),
              TextField(controller: source, maxLines: 2, decoration: const InputDecoration(labelText: 'Source officielle')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Valider')),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(apiServiceProvider).put<Map<String, dynamic>>('/paie/parametres/${p['id']}/validation', data: {
      'validePar': validePar.text.trim(),
      'qualiteValidateur': qualite,
      'source': source.text.trim(),
    });
    ref.invalidate(_parametresProvider);
    if (context.mounted) grhSnack(context, 'Validation enregistrée.');
  } catch (e) {
    if (context.mounted) grhSnack(context, messageErreur(e), error: true);
  }
}

// ── Rubriques ───────────────────────────────────────────────────────────────

class _RubriquesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(_rubriquesProvider);
    return GrhAsync<List<Map<String, dynamic>>>(
      value: value,
      onRetry: () => ref.invalidate(_rubriquesProvider),
      data: (items) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _editerRubrique(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle rubrique'),
            ),
          ),
          const SizedBox(height: 12),
          for (final r in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GrhSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            Text(r['libelle']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                            GrhBadge(_typesRubrique[r['type']] ?? r['type'].toString()),
                            if (r['actif'] != true) const GrhBadge('Inactive', tone: GrhBadgeTone.danger),
                          ]),
                          const SizedBox(height: 4),
                          Text('${r['code']} · ordre ${r['ordre']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                          Text('Formule : ${r['formule']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: () => _editerRubrique(context, ref, r),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _editerRubrique(BuildContext context, WidgetRef ref, Map<String, dynamic>? r) async {
  final code = TextEditingController(text: r?['code']?.toString() ?? '');
  final libelle = TextEditingController(text: r?['libelle']?.toString() ?? '');
  final ordre = TextEditingController(text: r?['ordre']?.toString() ?? '100');
  final formule = TextEditingController(text: r?['formule']?.toString() ?? '');
  String type = r?['type']?.toString() ?? 'GAIN';
  bool actif = r?['actif'] != false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(r == null ? 'Nouvelle rubrique' : 'Modifier ${r['code']}'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: code, enabled: r == null, decoration: const InputDecoration(labelText: 'Code')),
                TextField(controller: libelle, decoration: const InputDecoration(labelText: 'Libellé')),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [for (final t in _typesRubrique.entries) DropdownMenuItem(value: t.key, child: Text(t.value))],
                  onChanged: (v) => setState(() => type = v ?? type),
                ),
                TextField(controller: ordre, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ordre de calcul')),
                TextField(
                  controller: formule,
                  decoration: const InputDecoration(
                    labelText: 'Formule',
                    helperText: 'Variables : SALAIRE_BASE, BRUT, HEURES_SUP et les codes de paramètres.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: actif,
                  onChanged: (v) => setState(() => actif = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final data = {
    'code': code.text.trim().toUpperCase(),
    'libelle': libelle.text.trim(),
    'type': type,
    'ordre': int.tryParse(ordre.text.trim()) ?? 100,
    'formule': formule.text.trim(),
    'actif': actif,
  };
  try {
    final api = ref.read(apiServiceProvider);
    if (r == null) {
      await api.post<Map<String, dynamic>>('/paie/rubriques', data: data);
    } else {
      await api.put<Map<String, dynamic>>('/paie/rubriques/${r['id']}', data: data);
    }
    ref.invalidate(_rubriquesProvider);
    if (context.mounted) grhSnack(context, 'Rubrique enregistrée.');
  } catch (e) {
    if (context.mounted) grhSnack(context, messageErreur(e), error: true);
  }
}
