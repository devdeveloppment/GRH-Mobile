import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/evaluation_provider.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final isEmployee = auth.role == UserRole.employee;
    final evalsAsync = isEmployee
        ? ref.watch(myEvaluationsProvider)
        : ref.watch(evaluationsProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final canCreate = auth.role?.isHrFamily == true ||
        auth.role == UserRole.manager;
    final canValidate = auth.role?.isHrFamily ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.evaluations,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: isEmployee ? 'Mes évaluations' : 'Évaluations',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context, ref),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouvelle', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Row(
        children: [
          if (isWide)
            GrhSidebar(currentRoute: AppRoutes.evaluations, role: auth.role!),
          Expanded(
            child: evalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (evals) => evals.isEmpty
                  ? const Center(child: Text('Aucune évaluation'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: evals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _EvalCard(
                        eval: evals[i],
                        canValidate: canValidate,
                        onValidate: () async {
                          final id = (evals[i]['id'] as num).toInt();
                          final ok = await ref
                              .read(evaluationNotifierProvider.notifier)
                              .valider(id);
                          if (context.mounted) {
                            ref.invalidate(evaluationsProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(ok
                                      ? 'Évaluation validée.'
                                      : 'Erreur.')),
                            );
                          }
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    final employeIdCtrl = TextEditingController();
    final periodeCtrl = TextEditingController(
        text: '${DateTime.now().year}-S1');
    final noteCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvelle évaluation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: employeIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ID Employé *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: periodeCtrl,
              decoration: const InputDecoration(labelText: 'Période (ex: 2025-S1)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Note /20 *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(labelText: 'Commentaire'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                onPressed: () async {
                  final id = int.tryParse(employeIdCtrl.text);
                  final note = int.tryParse(noteCtrl.text);
                  if (id == null || note == null) return;
                  final ok = await ref
                      .read(evaluationNotifierProvider.notifier)
                      .create({
                    'employeId': id,
                    'periode': periodeCtrl.text.trim(),
                    'note': note,
                    'commentaire': commentCtrl.text.trim(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(evaluationsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Évaluation créée.' : 'Erreur.')),
                    );
                  }
                },
                child: const Text('Créer', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvalCard extends StatelessWidget {
  const _EvalCard({
    required this.eval,
    required this.canValidate,
    required this.onValidate,
  });

  final Map<String, dynamic> eval;
  final bool canValidate;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final note = eval['note'] as int? ?? 0;
    final color = note >= 14
        ? Colors.green
        : note >= 10
            ? Colors.orange
            : Colors.red;

    return GrhSurfaceCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            '$note',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(eval['employeNom'] as String? ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Période: ${eval['periode'] ?? ''}'),
            Text('Type: ${eval['type'] ?? 'ANNUELLE'}'),
            if (eval['evaluateurNom'] != null)
              Text('Évaluateur: ${eval['evaluateurNom']}',
                  style: const TextStyle(color: AppColors.text2, fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(label: eval['statut'] as String? ?? ''),
            if (canValidate && eval['statut'] == 'SOUMISE')
              TextButton(
                onPressed: onValidate,
                child: const Text('Valider',
                    style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
          ],
        ),
        // Pas de isThreeLine : la hauteur fixe déborde quand le sous-titre fait 3 lignes.
        isThreeLine: false,
      ),
    );
  }
}
