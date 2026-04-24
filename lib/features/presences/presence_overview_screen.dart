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
  ConsumerState<PresenceOverviewScreen> createState() => _PresenceOverviewScreenState();
}

class _PresenceOverviewScreenState extends ConsumerState<PresenceOverviewScreen> {
  late Future<List<Presence>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPresences();
  }

  Future<List<Presence>> _loadPresences() async {
    final response = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/presences');
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
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.presences,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: GrhAppBar(
          title: 'Présences',
          userName: auth.user?.fullName,
          onMenuTap: isWide ? null : () => Scaffold.of(context).openDrawer(),
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
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!;
                final presentCount = items.where((item) => item.statut == 'PRESENT').length;
                final lateCount = items.where((item) => item.statut == 'RETARD').length;
                final absentCount = items.where((item) => item.statut == 'ABSENT').length;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isWide ? 260 : double.infinity,
                          child: KpiCard(
                            title: 'Présents',
                            value: '$presentCount',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            trend: 3.4,
                          ),
                        ),
                        SizedBox(
                          width: isWide ? 260 : double.infinity,
                          child: KpiCard(
                            title: 'Retards',
                            value: '$lateCount',
                            icon: Icons.schedule_outlined,
                            color: AppColors.warning,
                            trend: -1.1,
                          ),
                        ),
                        SizedBox(
                          width: isWide ? 260 : double.infinity,
                          child: KpiCard(
                            title: 'Absences',
                            value: '$absentCount',
                            icon: Icons.person_off_outlined,
                            color: AppColors.danger,
                            trend: -0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.fact_check_outlined),
                            title: Text(AppFormatters.longDate(item.date)),
                            subtitle: Text(
                              'Arrivée ${AppFormatters.time(item.heureArrivee)} • Départ ${AppFormatters.time(item.heureDepart)}',
                            ),
                            trailing: StatusBadge(
                              label: item.statut,
                              type: item.statut == 'PRESENT'
                                  ? 'success'
                                  : item.statut == 'RETARD'
                                      ? 'warning'
                                      : 'error',
                            ),
                          ),
                        ),
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
