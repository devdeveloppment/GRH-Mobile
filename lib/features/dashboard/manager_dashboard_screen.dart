import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';

final _teamProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.get<Map<String, dynamic>>('/employees/my-team');
  final raw = resp.data?['items'] as List? ?? [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

final _pendingCongesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.get<Map<String, dynamic>>('/conges?statut=EN_ATTENTE');
  final raw = resp.data?['items'] as List? ?? [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final teamAsync = ref.watch(_teamProvider);
    final congesAsync = ref.watch(_pendingCongesProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.managerDashboard,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Bonjour, ${auth.user?.fullName ?? ""}',
            userName: 'Mon équipe',
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.managerDashboard, role: auth.role!),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_teamProvider);
                ref.invalidate(_pendingCongesProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── KPI row ──────────────────────────────────────────
                    teamAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (team) => Row(
                        children: [
                          _KpiTile(
                            icon: Icons.people_alt_outlined,
                            label: 'Membres',
                            value: '${team.length}',
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          congesAsync.when(
                            loading: () => const _KpiTile(
                              icon: Icons.beach_access_outlined,
                              label: 'Congés en attente',
                              value: '…',
                              color: Colors.orange,
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (conges) => _KpiTile(
                              icon: Icons.beach_access_outlined,
                              label: 'Congés en attente',
                              value: '${conges.length}',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Mon équipe ──────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mon équipe',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.go(AppRoutes.employees),
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('Tous les employés'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    teamAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Erreur: $e')),
                      data: (team) => team.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('Aucun membre dans votre équipe'),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: team.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) => _TeamMemberCard(member: team[i]),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // ── Demandes de congés en attente ───────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Demandes de congés',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.go(AppRoutes.conges),
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('Tout voir'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    congesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Erreur: $e')),
                      data: (conges) => conges.isEmpty
                          ? GrhSurfaceCard(
                              child: const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: Text('Aucune demande en attente')),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: conges.length > 5 ? 5 : conges.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) => _CongeCard(conge: conges[i], ref: ref),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GrhSurfaceCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: AppColors.text2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({required this.member});
  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final nom = member['nom'] as String? ?? '';
    final prenom = member['prenom'] as String? ?? '';
    final poste = member['poste'] as String? ?? member['posteIntitule'] as String? ?? '';
    final dept = member['departement'] as String? ?? member['service'] as String?;
    final initials = '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
        .toUpperCase();

    return GrhSurfaceCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          '$prenom $nom',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (poste.isNotEmpty) Text(poste),
            if (dept != null)
              Text(dept, style: const TextStyle(fontSize: 12, color: AppColors.text2)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.text2),
        isThreeLine: dept != null,
      ),
    );
  }
}

class _CongeCard extends StatelessWidget {
  const _CongeCard({required this.conge, required this.ref});
  final Map<String, dynamic> conge;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final employeNom = conge['nomEmploye'] as String? ?? conge['employeNom'] as String? ?? '';
    final type = conge['typeConge'] as String? ?? '';
    final debut = conge['dateDebut'] as String? ?? '';
    final fin = conge['dateFin'] as String? ?? '';
    final id = (conge['id'] as num?)?.toInt();

    return GrhSurfaceCard(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF3E0),
          child: Icon(Icons.beach_access_outlined, color: Colors.orange),
        ),
        title: Text(employeNom,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$type  •  $debut → $fin'),
        trailing: id != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    tooltip: 'Approuver',
                    onPressed: () => _approve(context, id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Refuser',
                    onPressed: () => _reject(context, id),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _approve(BuildContext context, int id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post<dynamic>('/conges/$id/approve');
      ref.invalidate(_pendingCongesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Congé approuvé.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.messageOf(e, "Erreur lors de l'approbation."))),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context, int id) async {
    try {
      final commentaire = await _askRejectReason(context);
      if (commentaire == null) return;
      final api = ref.read(apiServiceProvider);
      await api.post<dynamic>('/conges/$id/reject', data: {'commentaire': commentaire});
      ref.invalidate(_pendingCongesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Congé refusé.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.messageOf(e, 'Erreur lors du refus.'))),
        );
      }
    }
  }

  /// Motif du refus, transmis à l'employé. Renvoie null si l'utilisateur annule.
  Future<String?> _askRejectReason(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la demande'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Motif du refus (facultatif)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }
}
