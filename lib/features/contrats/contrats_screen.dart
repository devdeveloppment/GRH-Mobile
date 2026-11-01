import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

final _expirantProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp =
      await api.get<Map<String, dynamic>>('/contrats/expirant?jours=30');
  final raw = resp.data?['items'] as List? ?? [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

class ContratsScreen extends ConsumerWidget {
  const ContratsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final expirantAsync = ref.watch(_expirantProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.contrats,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Contrats',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide)
            GrhSidebar(currentRoute: AppRoutes.contrats, role: auth.role!),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Contrats expirant dans 30 jours',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: expirantAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
                    data: (contrats) {
                      if (contrats.isEmpty) {
                        return const Center(
                          child: Text('Aucun contrat expirant prochainement.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: contrats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ContratCard(contrat: contrats[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContratCard extends StatelessWidget {
  const _ContratCard({required this.contrat});
  final Map<String, dynamic> contrat;

  @override
  Widget build(BuildContext context) {
    final dateFin = contrat['dateFin'] as String?;
    final employeNom = contrat['employeNom'] as String? ?? '';
    final typeContrat = contrat['typeContrat'] as String? ?? '';
    final statut = contrat['statut'] as String? ?? '';

    return GrhSurfaceCard(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF3E0),
          child: Icon(Icons.description_outlined, color: Colors.orange),
        ),
        title: Text(employeNom,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: $typeContrat'),
            if (dateFin != null) Text('Expire le: $dateFin'),
            if (contrat['posteIntitule'] != null)
              Text('Poste: ${contrat['posteIntitule']}'),
          ],
        ),
        trailing: StatusBadge(label: statut),
        isThreeLine: true,
      ),
    );
  }
}
