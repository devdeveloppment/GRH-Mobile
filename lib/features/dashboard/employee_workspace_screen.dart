import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/conge_provider.dart';
import 'package:grh_mobile/core/providers/paie_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/features/conges/conge_request_screen.dart';
import 'package:grh_mobile/shared/models/presence.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';

class EmployeeWorkspaceScreen extends ConsumerStatefulWidget {
  const EmployeeWorkspaceScreen({super.key});

  @override
  ConsumerState<EmployeeWorkspaceScreen> createState() => _EmployeeWorkspaceScreenState();
}

class _EmployeeWorkspaceScreenState extends ConsumerState<EmployeeWorkspaceScreen> {
  int _index = 0;
  late Future<List<Presence>> _presenceFuture;

  @override
  void initState() {
    super.initState();
    _presenceFuture = _loadPresences();
  }

  Future<List<Presence>> _loadPresences() async {
    final response = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/presences/me');
    final raw = response.data?['items'] as List<dynamic>? ?? <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Presence.fromJson)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final conges = ref.watch(congeNotifierProvider);
    final paie = ref.watch(paieNotifierProvider);
    final user = auth.user;

    final pages = <Widget>[
      _ProfileTab(userName: user?.fullName ?? 'Collaborateur', email: user?.email ?? ''),
      FutureBuilder<List<Presence>>(
        future: _presenceFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) {
              final presence = items[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time_rounded),
                  title: Text(AppFormatters.longDate(presence.date)),
                  subtitle: Text(
                    'Arrivée ${AppFormatters.time(presence.heureArrivee)} • Départ ${AppFormatters.time(presence.heureDepart)}',
                  ),
                  trailing: Text(presence.statut),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
      ),
      const CongeRequestScreen(embedded: true),
      ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, index) {
          final item = paie.bulletins[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(item.periode),
              subtitle: Text(AppFormatters.currency(item.salaireNet)),
              trailing: IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: () async {
                  final path = await ref.read(paieNotifierProvider).downloadPayslip(
                        item.id,
                        item.nomEmploye ?? user?.fullName ?? 'employe',
                      );
                  if (!mounted) {
                    return;
                  }
                  if (path != null && !kIsWeb) {
                    await OpenFilex.open(path);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bulletin généré avec succès.')),
                  );
                },
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: paie.bulletins.length,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon espace'),
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Mon profil'),
          NavigationDestination(icon: Icon(Icons.access_time_outlined), label: 'Présences'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Mes congés'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Mon bulletin'),
        ],
      ),
      floatingActionButton: _index == 2 && conges.isLoading
          ? const FloatingActionButton.small(
              onPressed: null,
              child: CircularProgressIndicator(),
            )
          : null,
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.userName,
    required this.email,
  });

  final String userName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EmployeeAvatar(name: userName, size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(email),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    Chip(label: Text('Présence en temps réel')),
                    Chip(label: Text('Accès sécurisé JWT')),
                    Chip(label: Text('Bulletins PDF')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
