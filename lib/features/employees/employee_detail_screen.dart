import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/conge.dart';
import 'package:grh_mobile/shared/models/employe.dart';
import 'package:grh_mobile/shared/models/fiche_paie.dart';
import 'package:grh_mobile/shared/models/presence.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  const EmployeeDetailScreen({
    super.key,
    required this.matricule,
    this.employee,
  });

  final String matricule;
  final Employe? employee;

  @override
  ConsumerState<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  late Future<_EmployeeDetailBundle> _bundleFuture;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _loadBundle();
  }

  Future<_EmployeeDetailBundle> _loadBundle() async {
    final api = ref.read(apiServiceProvider);

    final employeeFuture = widget.employee != null
        ? Future.value(widget.employee)
        : api.get<Map<String, dynamic>>('/employees/${widget.matricule}').then(
              (response) => Employe.fromJson(response.data ?? <String, dynamic>{}),
            );
    final presencesFuture = api.get<Map<String, dynamic>>('/employees/${widget.matricule}/presences').then(
          (response) => ((response.data?['items'] as List<dynamic>?) ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(Presence.fromJson)
              .toList(growable: false),
        );
    final congesFuture = api.get<Map<String, dynamic>>('/employees/${widget.matricule}/conges').then(
          (response) => ((response.data?['items'] as List<dynamic>?) ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(Conge.fromJson)
              .toList(growable: false),
        );
    final paieFuture = api.get<Map<String, dynamic>>('/employees/${widget.matricule}/paie').then(
          (response) => ((response.data?['items'] as List<dynamic>?) ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(FichePaie.fromJson)
              .toList(growable: false),
        );

    final results = await Future.wait<dynamic>([
      employeeFuture,
      presencesFuture,
      congesFuture,
      paieFuture,
    ]);

    return _EmployeeDetailBundle(
      employee: results[0] as Employe,
      presences: results[1] as List<Presence>,
      conges: results[2] as List<Conge>,
      paies: results[3] as List<FichePaie>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: const GrhAppBar(title: 'Fiche Employé', showBack: true),
        body: FutureBuilder<_EmployeeDetailBundle>(
          future: _bundleFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final bundle = snapshot.data!;
            final employee = bundle.employee;

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      EmployeeAvatar(
                        name: employee.fullName,
                        imageUrl: employee.photoUrl,
                        size: 72,
                        showStatus: true,
                        isOnline: employee.presentAujourdHui ?? false,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.fullName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text('Matricule ${employee.matricule}'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                StatusBadge(
                                  label: employee.statut,
                                  type: employee.statut == 'ACTIF' ? 'success' : 'neutral',
                                ),
                                StatusBadge(
                                  label: employee.typeContrat,
                                  type: employee.typeContrat == 'CDI' ? 'success' : 'warning',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Infos Personnelles'),
                    Tab(text: 'Contrat'),
                    Tab(text: 'Présences'),
                    Tab(text: 'Congés'),
                    Tab(text: 'Paie'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _InfoTab(employee: employee),
                      _ContractTab(employee: employee),
                      _PresenceTab(items: bundle.presences),
                      _CongeTab(items: bundle.conges),
                      _PaieTab(items: bundle.paies),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.employee});

  final Employe employee;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Date de naissance', value: AppFormatters.shortDate(employee.dateNaissance)),
        _InfoRow(label: 'Genre', value: employee.genre ?? 'N/A'),
        _InfoRow(label: 'Nationalité', value: employee.nationalite ?? 'N/A'),
        _InfoRow(label: 'Email', value: employee.email),
        _InfoRow(label: 'Téléphone', value: employee.telephone ?? 'N/A'),
        _InfoRow(label: 'Adresse', value: employee.adresse ?? 'N/A'),
      ],
    );
  }
}

class _ContractTab extends StatelessWidget {
  const _ContractTab({required this.employee});

  final Employe employee;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Type de contrat', value: employee.typeContrat),
        _InfoRow(label: 'Date début', value: AppFormatters.shortDate(employee.dateEmbauche)),
        _InfoRow(label: 'Date fin', value: AppFormatters.shortDate(employee.dateFinContrat)),
        _InfoRow(label: 'Poste', value: employee.poste),
        _InfoRow(label: 'Salaire', value: AppFormatters.currency(employee.salaire)),
        _InfoRow(label: 'Service', value: employee.service),
      ],
    );
  }
}

class _PresenceTab extends StatelessWidget {
  const _PresenceTab({required this.items});

  final List<Presence> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(AppFormatters.longDate(item.date)),
            subtitle: Text(
              'Arrivée ${AppFormatters.time(item.heureArrivee)} • Départ ${AppFormatters.time(item.heureDepart)}',
            ),
            trailing: StatusBadge(
              label: item.statut,
              type: item.statut == 'PRESENT' ? 'success' : item.statut == 'RETARD' ? 'warning' : 'error',
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}

class _CongeTab extends StatelessWidget {
  const _CongeTab({required this.items});

  final List<Conge> items;

  @override
  Widget build(BuildContext context) {
    final solde = items
        .where((item) => item.statut == 'APPROUVE')
        .fold<int>(30, (current, item) => current - item.nombreJours);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: const Text('Solde disponible'),
            subtitle: Text('$solde jours restants'),
            trailing: const Icon(Icons.event_available_outlined),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                title: Text(item.typeConge),
                subtitle: Text(
                  '${AppFormatters.shortDate(item.dateDebut)} → ${AppFormatters.shortDate(item.dateFin)} • ${item.nombreJours} jours',
                ),
                trailing: StatusBadge(
                  label: item.statut,
                  type: item.statut == 'APPROUVE'
                      ? 'success'
                      : item.statut == 'EN_ATTENTE'
                          ? 'warning'
                          : 'error',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaieTab extends ConsumerWidget {
  const _PaieTab({required this.items});

  final List<FichePaie> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(item.periode),
            subtitle: Text('Salaire net ${AppFormatters.currency(item.salaireNet)}'),
            trailing: IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () async {
                final filePath = await ref.read(apiServiceProvider).downloadFile(
                      '/paie/${item.id}/bulletin/pdf',
                      'bulletin-${item.id}.pdf',
                    );
                if (filePath != null && !kIsWeb) {
                  await OpenFilex.open(filePath);
                }
              },
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}

class _EmployeeDetailBundle {
  const _EmployeeDetailBundle({
    required this.employee,
    required this.presences,
    required this.conges,
    required this.paies,
  });

  final Employe employee;
  final List<Presence> presences;
  final List<Conge> conges;
  final List<FichePaie> paies;
}
