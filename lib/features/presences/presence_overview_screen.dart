import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/presence.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/kpi_card.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

class PresenceOverviewScreen extends ConsumerStatefulWidget {
  const PresenceOverviewScreen({super.key});

  @override
  ConsumerState<PresenceOverviewScreen> createState() =>
      _PresenceOverviewScreenState();
}

class _PresenceOverviewScreenState
    extends ConsumerState<PresenceOverviewScreen> {
  late Future<List<Presence>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPresences();
  }

  Future<List<Presence>> _loadPresences() async {
    final response = await ref
        .read(apiServiceProvider)
        .get<Map<String, dynamic>>('/presences');
    final raw = response.data?['items'] as List<dynamic>? ?? <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Presence.fromJson)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.presences,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Présences',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.presences, role: auth.role!),
          Expanded(
            child: FutureBuilder<List<Presence>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Impossible de charger les présences.',
                      style: TextStyle(color: AppColors.text2, fontSize: 13),
                    ),
                  );
                }
                final items = snapshot.data!;
                final presentCount =
                    items.where((item) => item.statut == 'PRESENT').length;
                final lateCount =
                    items.where((item) => item.statut == 'RETARD').length;
                final absentCount =
                    items.where((item) => item.statut == 'ABSENT').length;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: isWide ? 240 : double.infinity,
                          child: KpiCard(
                            title: 'Présents',
                            value: '$presentCount',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            trend: 3.4,
                          ),
                        ),
                        SizedBox(
                          width: isWide ? 240 : double.infinity,
                          child: KpiCard(
                            title: 'Retards',
                            value: '$lateCount',
                            icon: Icons.schedule_outlined,
                            color: AppColors.warning,
                            trend: -1.1,
                          ),
                        ),
                        SizedBox(
                          width: isWide ? 240 : double.infinity,
                          child: KpiCard(
                            title: 'Absences',
                            value: '$absentCount',
                            icon: Icons.person_off_outlined,
                            color: AppColors.error,
                            trend: -0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: const Center(
                          child: Text(
                            'Aucune présence enregistrée.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.text2),
                          ),
                        ),
                      )
                    else
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PresenceTile(item: item),
                        ),
                      ),
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

class _PresenceTile extends StatelessWidget {
  const _PresenceTile({required this.item});

  final Presence item;

  @override
  Widget build(BuildContext context) {
    final statusType = switch (item.statut) {
      'PRESENT' => 'active',
      'RETARD' => 'pending',
      _ => 'rejected',
    };
    final statusLabel = switch (item.statut) {
      'PRESENT' => 'Présent',
      'RETARD' => 'Retard',
      _ => 'Absent',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppFormatters.longDate(item.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Arrivée ${AppFormatters.time(item.heureArrivee)} • Départ ${AppFormatters.time(item.heureDepart)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: statusLabel, type: statusType),
        ],
      ),
    );
  }
}
