import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/formation_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

class FormationsScreen extends ConsumerStatefulWidget {
  const FormationsScreen({super.key});

  @override
  ConsumerState<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends ConsumerState<FormationsScreen> {
  String? _statut;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final formationsAsync = ref.watch(formationsProvider(_statut));
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final canManage = auth.role?.isHrFamily ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.formations,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Formations',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouvelle', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Row(
        children: [
          if (isWide)
            GrhSidebar(currentRoute: AppRoutes.formations, role: auth.role!),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String?>(
                      segments: const [
                        ButtonSegment(value: null, label: Text('Toutes')),
                        ButtonSegment(value: 'PLANIFIEE', label: Text('Planifiées')),
                        ButtonSegment(value: 'EN_COURS', label: Text('En cours')),
                        ButtonSegment(value: 'TERMINEE', label: Text('Terminées')),
                      ],
                      selected: {_statut},
                      onSelectionChanged: (s) =>
                          setState(() => _statut = s.first),
                    ),
                  ),
                ),
                Expanded(
                  child: formationsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
                    data: (formations) => formations.isEmpty
                        ? const Center(child: Text('Aucune formation'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: formations.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) =>
                                _FormationCard(formation: formations[i]),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context) {
    final titreCtrl = TextEditingController();
    final formateurCtrl = TextEditingController();
    String type = 'INTERNE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouvelle formation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titreCtrl,
                decoration: const InputDecoration(labelText: 'Titre *'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['INTERNE', 'EXTERNE', 'E_LEARNING']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setModal(() => type = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: formateurCtrl,
                decoration: const InputDecoration(labelText: 'Formateur'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () async {
                    if (titreCtrl.text.trim().isEmpty) return;
                    final ok = await ref
                        .read(formationNotifierProvider.notifier)
                        .create({
                      'titre': titreCtrl.text.trim(),
                      'type': type,
                      'formateur': formateurCtrl.text.trim(),
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(formationsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(ok ? 'Formation créée.' : 'Erreur.')),
                      );
                    }
                  },
                  child: const Text('Créer',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormationCard extends StatelessWidget {
  const _FormationCard({required this.formation});
  final Map<String, dynamic> formation;

  @override
  Widget build(BuildContext context) {
    return GrhSurfaceCard(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE3F2FD),
          child: Icon(Icons.school_outlined, color: Colors.blue),
        ),
        title: Text(formation['titre'] as String? ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${formation['type'] ?? ''}'),
            if (formation['formateur'] != null)
              Text('Formateur: ${formation['formateur']}'),
            if (formation['dateDebut'] != null)
              Text('Début: ${formation['dateDebut']}'),
            Text('${formation['nbParticipants'] ?? 0} participant(s)'),
          ],
        ),
        trailing: StatusBadge(label: formation['statut'] as String? ?? ''),
        isThreeLine: true,
      ),
    );
  }
}
