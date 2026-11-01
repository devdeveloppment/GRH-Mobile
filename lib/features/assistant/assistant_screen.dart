import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';

final _assistantStatutProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final resp = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/assistant/statut');
  return resp.data ?? {};
});

const _libellesOutils = {
  'contrats_expirant': 'Contrats qui expirent (30 jours)',
  'absents_aujourdhui': "Absents aujourd'hui",
  'conges_en_attente': 'Congés en attente',
  'masse_salariale': 'Masse salariale du mois',
  'solde_conges': 'Mon solde de congés',
};

/// Assistant RH en lecture seule. Les réponses citent les données utilisées ;
/// aucune décision n'est prise par l'IA.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _question = TextEditingController();
  bool _busy = false;
  final List<_Echange> _echanges = [];

  Future<void> _ask() async {
    final q = _question.text.trim();
    if (q.isEmpty) return;
    setState(() => _busy = true);
    try {
      final resp = await ref.read(apiServiceProvider).post<Map<String, dynamic>>('/assistant/questions', data: {'question': q});
      final d = resp.data ?? {};
      setState(() {
        _echanges.insert(0, _Echange(q, d['reponse'] as String? ?? '', d['donnees'], d['noms'], d['avertissement'] as String?));
        _question.clear();
      });
    } catch (e) {
      _snack(ApiService.messageOf(e, "L'assistant n'a pas pu répondre."));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _tool(String nom) async {
    setState(() => _busy = true);
    try {
      final resp = await ref.read(apiServiceProvider).post<Map<String, dynamic>>('/assistant/outils/$nom', data: <String, dynamic>{});
      final d = resp.data ?? {};
      setState(() => _echanges.insert(0, _Echange(_libellesOutils[nom] ?? nom, null, [d], d['noms'], null)));
    } catch (e) {
      _snack(ApiService.messageOf(e, 'Consultation impossible.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final statut = ref.watch(_assistantStatutProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(child: GrhSidebar(currentRoute: AppRoutes.assistant, role: auth.role!, isDrawer: true)),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Assistant RH',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null) GrhSidebar(currentRoute: AppRoutes.assistant, role: auth.role!),
          Expanded(
            child: statut.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(ApiService.messageOf(e, "Impossible de joindre l'assistant."))),
              data: (s) {
                final actif = s['actif'] == true;
                final outils = (s['outils'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!actif)
                      _Info(s['message'] as String? ?? 'Assistant non configuré.'),
                    if (actif) ...[
                      TextField(
                        controller: _question,
                        minLines: 1,
                        maxLines: 3,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          labelText: 'Votre question',
                          hintText: 'Ex. : quels contrats expirent ce mois ?',
                          suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _busy ? null : _ask),
                        ),
                        onSubmitted: (_) => _busy ? null : _ask(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text('Consultations rapides (données directes, sans IA)',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in outils)
                          ActionChip(
                            label: Text(_libellesOutils[o['nom']] ?? o['nom'] as String),
                            onPressed: _busy ? null : () => _tool(o['nom'] as String),
                          ),
                      ],
                    ),
                    if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
                    const SizedBox(height: 12),
                    for (final e in _echanges) _EchangeCard(echange: e),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

class _Echange {
  _Echange(this.question, this.reponse, this.donnees, this.noms, this.avertissement);
  final String question;
  final String? reponse;
  final dynamic donnees;
  final dynamic noms;
  final String? avertissement;
}

class _EchangeCard extends StatelessWidget {
  const _EchangeCard({required this.echange});
  final _Echange echange;

  @override
  Widget build(BuildContext context) {
    final noms = (echange.noms as Map?)?.cast<String, dynamic>() ?? {};
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GrhSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(echange.question, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (echange.reponse != null) ...[
              const SizedBox(height: 6),
              Text(echange.reponse!),
            ],
            if (echange.avertissement != null) ...[
              const SizedBox(height: 6),
              Text(echange.avertissement!, style: const TextStyle(fontSize: 11, color: Colors.orange)),
            ],
            if (noms.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Personnes : ${noms.entries.map((e) => '${e.key} = ${e.value}').join(', ')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.text2)),
            ],
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Données utilisées', style: TextStyle(fontSize: 12)),
              children: [
                SelectableText(const JsonEncoder.withIndent('  ').convert(echange.donnees),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
