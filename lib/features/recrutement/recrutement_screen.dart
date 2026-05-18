import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/recrutement_provider.dart';
import 'package:grh_mobile/shared/widgets/app_form_field.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

class RecrutementScreen extends ConsumerStatefulWidget {
  const RecrutementScreen({super.key});

  @override
  ConsumerState<RecrutementScreen> createState() => _RecrutementScreenState();
}

class _RecrutementScreenState extends ConsumerState<RecrutementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _selectedStatut;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final offresAsync = ref.watch(offresProvider(_selectedStatut));
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final canEdit = auth.role?.isHrFamily ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.recrutement,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isWide
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.text1),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: const Text('Recrutement',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text1)),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.text2,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Offres d\'emploi'),
            Tab(text: 'Pipeline'),
          ],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showOffreForm(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouvelle offre', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Row(
        children: [
          if (isWide)
            GrhSidebar(currentRoute: AppRoutes.recrutement, role: auth.role!),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // Onglet Offres
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SegmentedButton<String?>(
                        segments: const [
                          ButtonSegment(value: null, label: Text('Toutes')),
                          ButtonSegment(value: 'PUBLIEE', label: Text('Publiées')),
                          ButtonSegment(value: 'FERMEE', label: Text('Fermées')),
                          ButtonSegment(value: 'POURVUE', label: Text('Pourvues')),
                        ],
                        selected: {_selectedStatut},
                        onSelectionChanged: (s) =>
                            setState(() => _selectedStatut = s.first),
                      ),
                    ),
                    Expanded(
                      child: offresAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Erreur: $e')),
                        data: (offres) => offres.isEmpty
                            ? const Center(child: Text('Aucune offre'))
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: offres.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) => _OffreCard(
                                  offre: offres[i],
                                  canEdit: canEdit,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                // Onglet Pipeline (simplifié)
                _buildPipeline(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeline() {
    final stages = ['RECUE', 'PRESELECTIONNE', 'ENTRETIEN', 'RETENU', 'REFUSE'];
    final colors = {
      'RECUE': Colors.blue,
      'PRESELECTIONNE': Colors.orange,
      'ENTRETIEN': Colors.purple,
      'RETENU': Colors.green,
      'REFUSE': Colors.red,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: stages.map((stage) {
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: (colors[stage] ?? Colors.grey).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      stage,
                      style: TextStyle(
                        color: colors[stage],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showOffreForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99)))),
                const SizedBox(height: 20),
                const Text('Nouvelle offre d\'emploi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('L\'offre sera publiée et visible pour les candidats.',
                    style: TextStyle(fontSize: 12, color: AppColors.text2)),
                const SizedBox(height: 20),
                AppFormField(
                  controller: titreCtrl,
                  label: 'Intitulé du poste *',
                  prefixIcon: Icons.work_outline,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 14),
                AppFormField(
                  controller: descCtrl,
                  label: 'Description du poste',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 4,
                  minLines: 3,
                  hint: 'Missions, profil recherché, compétences…',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final ok = await ref
                          .read(recrutementNotifierProvider.notifier)
                          .createOffre({
                        'titre': titreCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ref.invalidate(offresProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Offre publiée.' : 'Erreur.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.publish_rounded, size: 18),
                    label: const Text('Publier l\'offre'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OffreCard extends StatelessWidget {
  const _OffreCard({required this.offre, required this.canEdit});
  final Map<String, dynamic> offre;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final id = (offre['id'] as num?)?.toInt();
    final titre = offre['titre'] as String? ?? '';
    final statut = offre['statut'] as String? ?? '';
    final nbCandidatures = offre['nbCandidatures'] as int? ?? 0;

    return GrhSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.work_outline_rounded, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (offre['departementNom'] != null)
                        Text('${offre['departementNom']}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.text2)),
                    ],
                  ),
                ),
                StatusBadge(label: statut, type: _statutOffreType(statut)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.people_outline,
                  label: '$nbCandidatures candidature${nbCandidatures > 1 ? 's' : ''}',
                ),
                if (offre['dateLimite'] != null) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: 'Limite: ${offre['dateLimite']}',
                  ),
                ],
              ],
            ),
            if (id != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '${AppRoutes.recrutementCandidatures}/$id',
                        extra: {'titre': titre},
                      ),
                      icon: const Icon(Icons.people_alt_outlined, size: 16),
                      label: Text('$nbCandidatures candidature${nbCandidatures > 1 ? 's' : ''}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  if (statut == 'PUBLIEE') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyApplyLink(context, id, titre),
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Partager lien'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade600,
                          side: BorderSide(color: Colors.green.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyApplyLink(BuildContext context, int id, String titre) {
    // En prod ce serait l'URL web de l'appli.
    // En dev on copie un deeplink / URL publique.
    const baseUrl = 'https://grh.example.com';
    final link = '$baseUrl/apply/$id';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lien copié : $link'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}

String _statutOffreType(String s) => switch (s.toUpperCase()) {
  'PUBLIEE' => 'success',
  'POURVUE' => 'info',
  'FERMEE' => 'error',
  _ => 'pending',
};

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.text2),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text2)),
        ],
      ),
    );
  }
}
