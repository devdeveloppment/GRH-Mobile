import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/providers/recrutement_provider.dart';
import 'package:grh_mobile/shared/widgets/app_form_field.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

String _statutType(String s) {
  return switch (s.toUpperCase()) {
    'RETENU' => 'success',
    'ENTRETIEN' => 'info',
    'PRESELECTIONNE' => 'warning',
    'REFUSE' => 'error',
    _ => 'pending',
  };
}

class CandidaturesScreen extends ConsumerWidget {
  const CandidaturesScreen({
    super.key,
    required this.offreId,
    required this.offreTitre,
  });

  final int offreId;
  final String offreTitre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCandidatures = ref.watch(candidaturesProvider(offreId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(offreTitre,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const Text('Candidatures reçues',
                style: TextStyle(fontSize: 12, color: AppColors.text2)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.text2),
            onPressed: () => ref.invalidate(candidaturesProvider(offreId)),
          ),
        ],
      ),
      body: asyncCandidatures.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (candidatures) {
          if (candidatures.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('Aucune candidature reçue',
                      style: TextStyle(fontSize: 16, color: AppColors.text2)),
                ],
              ),
            );
          }

          // Grouper par statut
          final grouped = <String, List<Map<String, dynamic>>>{};
          for (final c in candidatures) {
            final s = c['statut'] as String? ?? 'RECUE';
            grouped.putIfAbsent(s, () => []).add(c);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Résumé pipeline
              _PipelineSummary(grouped: grouped),
              const SizedBox(height: 20),
              // Liste complète
              for (final c in candidatures) ...[
                _CandidatureCard(
                  candidature: c,
                  onTap: () => _showDetail(context, ref, c, offreId),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref,
      Map<String, dynamic> candidature, int offreId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CandidatureDetailSheet(
        candidature: candidature,
        offreId: offreId,
        offreTitre: offreTitre,
        onUpdated: () => ref.invalidate(candidaturesProvider(offreId)),
      ),
    );
  }
}

// ── Résumé pipeline ────────────────────────────────────────────────────────────

class _PipelineSummary extends StatelessWidget {
  const _PipelineSummary({required this.grouped});
  final Map<String, List<Map<String, dynamic>>> grouped;

  static const _stages = [
    ('RECUE', 'Reçues', Colors.blue),
    ('PRESELECTIONNE', 'Présélectionnés', Colors.orange),
    ('ENTRETIEN', 'Entretiens', Colors.purple),
    ('RETENU', 'Retenus', Colors.green),
    ('REFUSE', 'Refusés', Colors.red),
  ];

  @override
  Widget build(BuildContext context) {
    return GrhSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pipeline de recrutement',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: _stages.map((stage) {
                final count = grouped[stage.$1]?.length ?? 0;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: stage.$3.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: stage.$3),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(stage.$2,
                          style: const TextStyle(fontSize: 10, color: AppColors.text2),
                          textAlign: TextAlign.center),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte candidature ──────────────────────────────────────────────────────────

class _CandidatureCard extends StatelessWidget {
  const _CandidatureCard({required this.candidature, required this.onTap});
  final Map<String, dynamic> candidature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nom = candidature['nom'] as String? ?? '';
    final prenom = candidature['prenom'] as String? ?? '';
    final email = candidature['email'] as String? ?? '';
    final statut = candidature['statut'] as String? ?? '';
    final hasCv = candidature['hasCv'] as bool? ?? false;
    final createdAt = candidature['createdAt'] as String? ?? '';
    final initials = '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: GrhSurfaceCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(initials,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$prenom $nom',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(email, style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusBadge(label: statut, type: _statutType(statut)),
                        if (hasCv) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attach_file_rounded, size: 10, color: Colors.green.shade700),
                                const SizedBox(width: 3),
                                Text('CV joint',
                                    style: TextStyle(fontSize: 10, color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.chevron_right_rounded, color: AppColors.text2),
                  if (createdAt.isNotEmpty)
                    Text(createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt,
                        style: const TextStyle(fontSize: 10, color: AppColors.text2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fiche détail candidature ───────────────────────────────────────────────────

class CandidatureDetailSheet extends ConsumerStatefulWidget {
  const CandidatureDetailSheet({
    super.key,
    required this.candidature,
    required this.offreId,
    required this.offreTitre,
    required this.onUpdated,
  });

  final Map<String, dynamic> candidature;
  final int offreId;
  final String offreTitre;
  final VoidCallback onUpdated;

  @override
  ConsumerState<CandidatureDetailSheet> createState() =>
      _CandidatureDetailSheetState();
}

class _CandidatureDetailSheetState extends ConsumerState<CandidatureDetailSheet> {
  bool _showEmbaucherForm = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.candidature;
    final nom = c['nom'] as String? ?? '';
    final prenom = c['prenom'] as String? ?? '';
    final email = c['email'] as String? ?? '';
    final telephone = c['telephone'] as String?;
    final statut = c['statut'] as String? ?? '';
    final hasCv = c['hasCv'] as bool? ?? false;
    final cvNom = c['cvNomFichier'] as String?;
    final lettre = c['lettreMotivation'] as String?;
    final id = (c['id'] as num?)?.toInt() ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            // ── En-tête ──
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$prenom $nom',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text1)),
                            Text(email,
                                style: const TextStyle(fontSize: 13, color: AppColors.text2)),
                            if (telephone != null)
                              Text(telephone,
                                  style: const TextStyle(fontSize: 13, color: AppColors.text2)),
                          ],
                        ),
                      ),
                      StatusBadge(label: statut, type: _statutType(statut)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Corps scrollable ──
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Actions rapides pipeline
                  if (statut != 'RETENU' && statut != 'REFUSE')
                    _PipelineActions(
                      id: id,
                      statut: statut,
                      onChanged: () {
                        widget.onUpdated();
                        Navigator.of(context).pop();
                      },
                    ),

                  const SizedBox(height: 16),

                  // CV
                  if (hasCv)
                    _InfoCard(
                      icon: Icons.description_outlined,
                      iconColor: Colors.green.shade600,
                      title: 'CV joint',
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cvNom ?? 'CV',
                              style: const TextStyle(fontSize: 14, color: AppColors.text1),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _downloadCv(id),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Télécharger'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Lettre de motivation
                  if (lettre != null && lettre.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.notes_rounded,
                      iconColor: Colors.blue.shade600,
                      title: 'Lettre de motivation',
                      child: Text(lettre,
                          style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.text1)),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Bouton Embaucher ──
                  if (statut != 'REFUSE')
                    if (_showEmbaucherForm)
                      _EmbaucherForm(
                        candidatureId: id,
                        defaultPoste: widget.offreTitre,
                        onDone: () {
                          widget.onUpdated();
                          Navigator.of(context).pop();
                        },
                        onCancel: () => setState(() => _showEmbaucherForm = false),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => setState(() => _showEmbaucherForm = true),
                          icon: const Icon(Icons.how_to_reg_rounded),
                          label: const Text('Embaucher ce candidat'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                  // Bouton Refuser
                  if (statut != 'REFUSE' && statut != 'RETENU') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatut(id, 'REFUSE'),
                        icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                        label: const Text('Refuser la candidature',
                            style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadCv(int id) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement du CV en cours…')),
    );
    try {
      await ref.read(recrutementNotifierProvider.notifier).downloadCv(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateStatut(int id, String statut) async {
    await ref.read(recrutementNotifierProvider.notifier).updateStatutCandidature(id, statut);
    widget.onUpdated();
    if (mounted) Navigator.of(context).pop();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GrhSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(title,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: iconColor)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _PipelineActions extends ConsumerWidget {
  const _PipelineActions({
    required this.id,
    required this.statut,
    required this.onChanged,
  });
  final int id;
  final String statut;
  final VoidCallback onChanged;

  static const _transitions = {
    'RECUE': ('PRESELECTIONNE', 'Présélectionner', Icons.star_outline_rounded, Colors.orange),
    'PRESELECTIONNE': ('ENTRETIEN', 'Planifier entretien', Icons.event_outlined, Colors.purple),
    'ENTRETIEN': ('RETENU', 'Marquer retenu', Icons.check_circle_outline, Colors.green),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = _transitions[statut];
    if (next == null) return const SizedBox.shrink();

    return GrhSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Avancer dans le pipeline',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text2)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(recrutementNotifierProvider.notifier)
                      .updateStatutCandidature(id, next.$1);
                  onChanged();
                },
                icon: Icon(next.$3, color: next.$4, size: 18),
                label: Text(next.$2, style: TextStyle(color: next.$4)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: next.$4.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formulaire d'embauche ──────────────────────────────────────────────────────

class _EmbaucherForm extends ConsumerStatefulWidget {
  const _EmbaucherForm({
    required this.candidatureId,
    required this.defaultPoste,
    required this.onDone,
    required this.onCancel,
  });
  final int candidatureId;
  final String defaultPoste;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  ConsumerState<_EmbaucherForm> createState() => _EmbaucherFormState();
}

class _EmbaucherFormState extends ConsumerState<_EmbaucherForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _poste;
  late final TextEditingController _service;
  late final TextEditingController _salaire;
  String _typeContrat = 'CDI';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _poste = TextEditingController(text: widget.defaultPoste);
    _service = TextEditingController();
    _salaire = TextEditingController();
  }

  @override
  void dispose() {
    _poste.dispose(); _service.dispose(); _salaire.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GrhSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.how_to_reg_rounded,
                        color: Colors.green.shade700, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Embauche',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text1)),
                        Text('Un compte employé sera créé automatiquement',
                            style: TextStyle(fontSize: 11, color: AppColors.text2)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.text2),
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
              const Divider(height: 20),
              AppFormField(
                controller: _poste,
                label: 'Intitulé du poste *',
                prefixIcon: Icons.work_outline,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              AppFormField(
                controller: _service,
                label: 'Département / Service *',
                prefixIcon: Icons.business_outlined,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              AppDropdownField<String>(
                label: 'Type de contrat',
                value: _typeContrat,
                prefixIcon: Icons.article_outlined,
                items: const [
                  DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                  DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                  DropdownMenuItem(value: 'STAGE', child: Text('Stage')),
                ],
                onChanged: (v) => setState(() => _typeContrat = v ?? 'CDI'),
              ),
              const SizedBox(height: 12),
              AppFormField(
                controller: _salaire,
                label: 'Salaire brut (FCFA)',
                prefixIcon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _embaucher,
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Confirmer l\'embauche'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _embaucher() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final matricule = await ref
          .read(recrutementNotifierProvider.notifier)
          .embaucher(
            widget.candidatureId,
            poste: _poste.text.trim(),
            service: _service.text.trim(),
            typeContrat: _typeContrat,
            salaire: double.tryParse(_salaire.text.trim()) ?? 0,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employé créé avec succès ! Matricule : $matricule'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onDone();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
