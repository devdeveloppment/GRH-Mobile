import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_page_scaffold.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';

final _entreprisesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final r = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/plateforme/entreprises');
  return (r.data?['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
});

final _detailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) async {
  final r = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/plateforme/entreprises/$id');
  return r.data ?? {};
});

const _offres = {
  'ESSAI': 'Essai',
  'ESSENTIEL': 'Essentiel',
  'PRO': 'Pro',
  'SUR_MESURE': 'Sur mesure',
};

/// Plateforme SaaS (SUPER_ADMIN) : entreprises clientes, statut et offre.
/// Les offres sont déclaratives : aucune facturation ni aucun paiement n'est géré ici.
class PlateformeEntreprisesScreen extends ConsumerWidget {
  const PlateformeEntreprisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(_entreprisesProvider);
    return GrhPageScaffold(
      title: 'Entreprises clientes',
      route: AppRoutes.plateforme,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('nouvelleEntreprise'),
        backgroundColor: AppColors.accent,
        onPressed: () => _creer(context, ref),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nouvelle entreprise'),
      ),
      body: GrhAsync<List<Map<String, dynamic>>>(
        value: value,
        onRetry: () => ref.invalidate(_entreprisesProvider),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            const GrhBanner(
              'Les offres sont déclaratives : aucune facturation ni aucun paiement n\'est réalisé par l\'application. '
              'Une entreprise suspendue est déconnectée immédiatement.',
            ),
            const SizedBox(height: 12),
            for (final e in items) _EntrepriseCard(entreprise: e),
          ],
        ),
      ),
    );
  }
}

class _EntrepriseCard extends StatelessWidget {
  const _EntrepriseCard({required this.entreprise});

  final Map<String, dynamic> entreprise;

  @override
  Widget build(BuildContext context) {
    final active = entreprise['statut'] == 'ACTIVE';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => _DetailEntreprise(id: (entreprise['id'] as num).toInt()),
        )),
        child: GrhSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text((entreprise['nom']?.toString() ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entreprise['nom']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${entreprise['slug']} · ${entreprise['pays'] ?? ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                  ],
                ),
              ),
              Wrap(spacing: 6, children: [
                GrhBadge(_offres[entreprise['offre']] ?? entreprise['offre'].toString()),
                GrhBadge(active ? 'Active' : 'Suspendue', tone: active ? GrhBadgeTone.success : GrhBadgeTone.danger),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _creer(BuildContext context, WidgetRef ref) async {
  final nom = TextEditingController();
  final slug = TextEditingController();
  final email = TextEditingController();
  String offre = 'ESSAI';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Nouvelle entreprise'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nom, decoration: const InputDecoration(labelText: 'Nom')),
              TextField(
                controller: slug,
                decoration: const InputDecoration(
                  labelText: 'Identifiant public (slug)',
                  helperText: 'minuscules, chiffres et tirets ; non modifiable ensuite',
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: offre,
                decoration: const InputDecoration(labelText: 'Offre'),
                items: [for (final o in _offres.entries) DropdownMenuItem(value: o.key, child: Text(o.value))],
                onChanged: (v) => setState(() => offre = v ?? offre),
              ),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "E-mail de l'administrateur"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Créer')),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    final r = await ref.read(apiServiceProvider).post<Map<String, dynamic>>('/plateforme/entreprises', data: {
      'nom': nom.text.trim(),
      'slug': slug.text.trim(),
      'offre': offre,
      'adminEmail': email.text.trim(),
    });
    ref.invalidate(_entreprisesProvider);
    final mdp = r.data?['motDePasseTemporaire']?.toString();
    if (!context.mounted) return;
    if (mdp == null) {
      grhSnack(context, 'Entreprise créée.');
      return;
    }
    // Le mot de passe temporaire n'est affiché qu'une seule fois.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entreprise créée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Administrateur : ${email.text.trim()}'),
            const SizedBox(height: 8),
            const Text('Mot de passe temporaire (affiché une seule fois, à changer à la première connexion) :'),
            SelectableText(mdp, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: mdp)),
            child: const Text('Copier'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) grhSnack(context, messageErreur(e), error: true);
  }
}

class _DetailEntreprise extends ConsumerWidget {
  const _DetailEntreprise({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(_detailProvider(id));
    void rafraichir() {
      ref.invalidate(_detailProvider(id));
      ref.invalidate(_entreprisesProvider);
    }

    Future<void> appel(Future<void> Function() action, String succes) async {
      try {
        await action();
        rafraichir();
        if (context.mounted) grhSnack(context, succes);
      } catch (e) {
        if (context.mounted) grhSnack(context, messageErreur(e), error: true);
      }
    }

    final api = ref.read(apiServiceProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Fiche entreprise')),
      body: GrhAsync<Map<String, dynamic>>(
        value: value,
        onRetry: rafraichir,
        data: (e) {
          final active = e['statut'] == 'ACTIVE';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GrhSurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['nom']?.toString() ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _ligne('Identifiant public', e['slug']),
                    _ligne('Pays', e['pays']),
                    _ligne('Statut', active ? 'Active' : 'Suspendue'),
                    _ligne('Offre', _offres[e['offre']] ?? e['offre']),
                    if (e['dateFinEssai'] != null) _ligne("Fin d'essai", formatDate(e['dateFinEssai'] as String?)),
                    _ligne('Créée le', formatDate(e['creeLe'] as String?)),
                    _ligne('Utilisateurs', '${e['utilisateursActifs']} actifs / ${e['utilisateurs']}'),
                    _ligne('Administrateurs', (e['administrateurs'] as List? ?? []).join(', ')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _modifier(context, e, (data) => appel(
                        () => api.put<Map<String, dynamic>>('/plateforme/entreprises/$id', data: data),
                        'Informations enregistrées.')),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _changerOffre(context, e, (data) => appel(
                        () => api.put<Map<String, dynamic>>('/plateforme/entreprises/$id/offre', data: data),
                        'Offre modifiée.')),
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text("Changer d'offre"),
                  ),
                  if (id != 1)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: active ? AppColors.error : AppColors.success),
                      onPressed: () async {
                        final confirme = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(active ? 'Suspendre cette entreprise ?' : 'Réactiver cette entreprise ?'),
                            content: Text(active
                                ? 'Tous ses utilisateurs seront déconnectés immédiatement. Les données sont conservées.'
                                : 'Ses utilisateurs pourront de nouveau se connecter.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
                            ],
                          ),
                        );
                        if (confirme == true) {
                          await appel(
                              () => api.put<Map<String, dynamic>>('/plateforme/entreprises/$id/statut',
                                  data: {'statut': active ? 'SUSPENDUE' : 'ACTIVE'}),
                              active ? 'Entreprise suspendue.' : 'Entreprise réactivée.');
                        }
                      },
                      icon: Icon(active ? Icons.block : Icons.check_circle_outline),
                      label: Text(active ? 'Suspendre' : 'Réactiver'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ligne(String label, Object? valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: Text(label, style: const TextStyle(color: AppColors.text2))),
            Expanded(child: Text(valeur?.toString() ?? '—')),
          ],
        ),
      );
}

Future<void> _modifier(BuildContext context, Map<String, dynamic> e, Future<void> Function(Map<String, String>) save) async {
  final nom = TextEditingController(text: e['nom']?.toString() ?? '');
  final pays = TextEditingController(text: e['pays']?.toString() ?? '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Modifier les informations'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nom, decoration: const InputDecoration(labelText: 'Nom')),
            TextField(controller: pays, decoration: const InputDecoration(labelText: 'Pays (code ISO, ex. TG)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
      ],
    ),
  );
  if (ok == true) await save({'nom': nom.text.trim(), 'pays': pays.text.trim().toUpperCase()});
}

Future<void> _changerOffre(
    BuildContext context, Map<String, dynamic> e, Future<void> Function(Map<String, String>) save) async {
  String offre = e['offre']?.toString() ?? 'ESSAI';
  final finEssai = TextEditingController(text: e['dateFinEssai']?.toString() ?? '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text("Changer d'offre"),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: offre,
                decoration: const InputDecoration(labelText: 'Offre'),
                items: [for (final o in _offres.entries) DropdownMenuItem(value: o.key, child: Text(o.value))],
                onChanged: (v) => setState(() => offre = v ?? offre),
              ),
              if (offre == 'ESSAI')
                TextField(
                  controller: finEssai,
                  decoration: const InputDecoration(labelText: "Fin d'essai (AAAA-MM-JJ, 30 jours si vide)"),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    ),
  );
  if (ok == true) {
    await save({'offre': offre, if (offre == 'ESSAI' && finEssai.text.trim().isNotEmpty) 'dateFinEssai': finEssai.text.trim()});
  }
}
