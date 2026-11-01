import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';

final _parametresRhProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/parametres-rh');
  return (resp.data?['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
});

final _feriesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/jours-feries');
  return (resp.data?['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
});

final _heuresSupProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final now = DateTime.now();
  final debut = DateTime(now.year, now.month, 1);
  String f(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final resp = await ref
      .read(apiServiceProvider)
      .get<Map<String, dynamic>>('/presences/heures-supplementaires?debut=${f(debut)}&fin=${f(now)}');
  return resp.data ?? {};
});

const _libellesParametres = {
  'CONGES_MODE_DECOMPTE': 'Décompte des jours de congé',
  'CONGES_ACQUISITION_JOURS_PAR_MOIS': 'Jours de congé acquis par mois',
  'HEURES_JOUR_NORMALES': 'Durée normale de travail par jour (heures)',
};

/// Paramétrage RH : règles de décompte, jours fériés, heures supplémentaires, acquisition.
/// Aucune valeur légale n'est imposée : les valeurs doivent être validées (Code du travail applicable).
class ParametrageRhScreen extends ConsumerWidget {
  const ParametrageRhScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final isAdmin = auth.role?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(child: GrhSidebar(currentRoute: AppRoutes.parametrageRh, role: auth.role!, isDrawer: true)),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Paramétrage RH',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null) GrhSidebar(currentRoute: AppRoutes.parametrageRh, role: auth.role!),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _Avertissement(),
                const SizedBox(height: 12),
                _ParametresSection(editable: isAdmin),
                const SizedBox(height: 12),
                const _FeriesSection(),
                const SizedBox(height: 12),
                const _HeuresSupSection(),
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  const _AcquisitionSection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: error ? Colors.red.shade700 : null),
  );
}

class _Avertissement extends StatelessWidget {
  const _Avertissement();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Aucune règle légale n'est fournie par défaut. Les valeurs (décompte des congés, acquisition, "
              'durée du travail, jours fériés) doivent être vérifiées selon le Code du travail applicable.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ],
      );
}

class _ParametresSection extends ConsumerWidget {
  const _ParametresSection({required this.editable});
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_parametresRhProvider);
    return GrhSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Paramètres'),
          const SizedBox(height: 8),
          async.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(ApiService.messageOf(e, 'Chargement impossible.')),
            data: (items) => Column(
              children: [
                for (final p in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_libellesParametres[p['cle']] ?? p['cle'] as String),
                    subtitle: Text((p['valeur'] as String?) ?? 'Non renseigné (fonction désactivée)'),
                    trailing: editable
                        ? IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Modifier',
                            onPressed: () => _edit(context, ref, p),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Map<String, dynamic> p) async {
    final cle = p['cle'] as String;
    String? valeur;
    if (cle == 'CONGES_MODE_DECOMPTE') {
      valeur = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Décompte des jours de congé'),
          children: [
            for (final m in const {
              'CALENDAIRES': 'Calendaires (tous les jours)',
              'OUVRABLES': 'Ouvrables (lundi-samedi, hors fériés)',
              'OUVRES': 'Ouvrés (lundi-vendredi, hors fériés)',
            }.entries)
              SimpleDialogOption(onPressed: () => Navigator.pop(ctx, m.key), child: Text(m.value)),
          ],
        ),
      );
    } else {
      final ctrl = TextEditingController(text: p['valeur'] as String? ?? '');
      valeur = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_libellesParametres[cle] ?? cle),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(helperText: 'Laisser vide pour désactiver'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Enregistrer')),
          ],
        ),
      );
    }
    if (valeur == null) return;
    try {
      await ref.read(apiServiceProvider).put<void>('/parametres-rh/$cle', data: {'valeur': valeur});
      ref.invalidate(_parametresRhProvider);
      ref.invalidate(_heuresSupProvider);
      if (context.mounted) _snack(context, 'Paramètre enregistré.');
    } catch (e) {
      if (context.mounted) _snack(context, ApiService.messageOf(e, 'Enregistrement impossible.'), error: true);
    }
  }
}

class _FeriesSection extends ConsumerWidget {
  const _FeriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_feriesProvider);
    return GrhSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            'Jours fériés',
            trailing: TextButton.icon(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ),
          async.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(ApiService.messageOf(e, 'Chargement impossible.')),
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Aucun jour férié saisi.', style: TextStyle(color: AppColors.text2)),
                  )
                : Column(
                    children: [
                      for (final j in items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_outlined),
                          title: Text(j['libelle'] as String? ?? ''),
                          subtitle: Text(j['date'] as String? ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Supprimer',
                            onPressed: () => _delete(context, ref, (j['id'] as num).toInt()),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (date == null || !context.mounted) return;
    final ctrl = TextEditingController();
    final libelle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Libellé du jour férié'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Ajouter')),
        ],
      ),
    );
    if (libelle == null || libelle.isEmpty) return;
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      await ref.read(apiServiceProvider).post<Map<String, dynamic>>('/jours-feries', data: {'date': d, 'libelle': libelle});
      ref.invalidate(_feriesProvider);
    } catch (e) {
      if (context.mounted) _snack(context, ApiService.messageOf(e, 'Ajout impossible.'), error: true);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(apiServiceProvider).delete<void>('/jours-feries/$id');
      ref.invalidate(_feriesProvider);
    } catch (e) {
      if (context.mounted) _snack(context, ApiService.messageOf(e, 'Suppression impossible.'), error: true);
    }
  }
}

class _HeuresSupSection extends ConsumerWidget {
  const _HeuresSupSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_heuresSupProvider);
    return GrhSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Heures supplémentaires (mois en cours)'),
          const SizedBox(height: 8),
          async.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(ApiService.messageOf(e, 'Chargement impossible.')),
            data: (r) {
              if (r['configure'] != true) {
                return Text(r['message'] as String? ?? 'Calcul désactivé.',
                    style: const TextStyle(color: AppColors.text2));
              }
              final items = (r['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
              if (items.isEmpty) {
                return const Text('Aucune heure supplémentaire sur la période.', style: TextStyle(color: AppColors.text2));
              }
              return Column(
                children: [
                  for (final i in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(i['nom'] as String? ?? ''),
                      subtitle: Text(i['matricule'] as String? ?? ''),
                      trailing: Text('${i['heuresSupplementaires']} h',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AcquisitionSection extends ConsumerStatefulWidget {
  const _AcquisitionSection();

  @override
  ConsumerState<_AcquisitionSection> createState() => _AcquisitionSectionState();
}

class _AcquisitionSectionState extends ConsumerState<_AcquisitionSection> {
  bool _running = false;
  String? _result;

  Future<void> _run() async {
    final prev = DateTime(DateTime.now().year, DateTime.now().month - 1);
    setState(() => _running = true);
    try {
      final resp = await ref
          .read(apiServiceProvider)
          .post<Map<String, dynamic>>('/conges/acquisitions?month=${prev.month}&year=${prev.year}');
      final d = resp.data ?? {};
      setState(() => _result = d['active'] == true
          ? '${d['employes']} employé(s) crédité(s) pour ${d['periode']} (une seule fois par mois).'
          : (d['message'] as String? ?? 'Acquisition désactivée.'));
    } catch (e) {
      setState(() => _result = ApiService.messageOf(e, "L'acquisition a échoué."));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GrhSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Acquisition des congés'),
          const SizedBox(height: 4),
          const Text(
            "Exécutée automatiquement le 1er de chaque mois. Vous pouvez la lancer pour le mois précédent ; "
            "elle n'est jamais appliquée deux fois.",
            style: TextStyle(fontSize: 12, color: AppColors.text2),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _running ? null : _run,
            child: Text(_running ? 'En cours…' : 'Lancer pour le mois précédent'),
          ),
          if (_result != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_result!)),
        ],
      ),
    );
  }
}
