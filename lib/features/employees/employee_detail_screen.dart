import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:grh_mobile/features/employees/employee_detail_panels.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/conge.dart';
import 'package:grh_mobile/shared/models/employe.dart';
import 'package:grh_mobile/shared/models/fiche_paie.dart';
import 'package:grh_mobile/shared/models/presence.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
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
  ConsumerState<EmployeeDetailScreen> createState() =>
      _EmployeeDetailScreenState();
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

    final employeeFuture = api
        .get<Map<String, dynamic>>('/employees/${widget.matricule}')
        .then((r) => Employe.fromJson(r.data ?? <String, dynamic>{}));
    final presencesFuture = api
        .get<Map<String, dynamic>>('/employees/${widget.matricule}/presences')
        .then((r) =>
            ((r.data?['items'] as List<dynamic>?) ?? <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(Presence.fromJson)
                .toList(growable: false));
    final congesFuture = api
        .get<Map<String, dynamic>>('/employees/${widget.matricule}/conges')
        .then((r) =>
            ((r.data?['items'] as List<dynamic>?) ?? <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(Conge.fromJson)
                .toList(growable: false));
    final paieFuture = api
        .get<Map<String, dynamic>>('/employees/${widget.matricule}/paie')
        .then((r) =>
            ((r.data?['items'] as List<dynamic>?) ?? <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(FichePaie.fromJson)
                .toList(growable: false))
        .catchError((Object _) => <FichePaie>[]);

    final results = await Future.wait<dynamic>(
        [employeeFuture, presencesFuture, congesFuture, paieFuture]);

    return _EmployeeDetailBundle(
      employee: results[0] as Employe,
      presences: results[1] as List<Presence>,
      conges: results[2] as List<Conge>,
      paies: results[3] as List<FichePaie>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    return DefaultTabController(
      length: 6,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        drawer: isWide || auth.role == null
            ? null
            : Drawer(
                child: GrhSidebar(
                  currentRoute: AppRoutes.employees,
                  role: auth.role!,
                  isDrawer: true,
                ),
              ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Builder(
            builder: (ctx) => GrhAppBar(
              title: "Profil de l'employé",
              showBack: true,
              userName: auth.user?.fullName,
              onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        body: Row(
          children: [
            if (isWide && auth.role != null)
              GrhSidebar(
                  currentRoute: AppRoutes.employees, role: auth.role!),
            Expanded(
              child: FutureBuilder<_EmployeeDetailBundle>(
                future: _bundleFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bundle = snapshot.data!;
                  final employee = bundle.employee;

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // ── Breadcrumb ──
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.employees),
                            child: Text(
                              'Employés',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.text2),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.chevron_right_rounded,
                                size: 14, color: AppColors.text2),
                          ),
                          Text(
                            'Détail',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.text2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Carte profil ──
                      _ProfileCard(employee: employee),
                      const SizedBox(height: 18),

                      // ── Barre d'onglets ──
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.border, width: 0.5),
                        ),
                        child: const TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          indicatorColor: AppColors.accent,
                          indicatorWeight: 2,
                          labelColor: AppColors.accent,
                          unselectedLabelColor: AppColors.text2,
                          labelStyle: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          tabs: [
                            Tab(text: 'Informations'),
                            Tab(text: 'Contrat'),
                            Tab(text: 'Paie'),
                            Tab(text: 'Compétences'),
                            Tab(text: 'Documents'),
                            Tab(text: 'Historique'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Contenu onglets ──
                      SizedBox(
                        height: 820,
                        child: TabBarView(
                          children: [
                            _InformationTab(employee: employee),
                            _ContractTab(
                              employee: employee,
                              onChanged: () => setState(() => _bundleFuture = _loadBundle()),
                            ),
                            _PayrollTab(items: bundle.paies),
                            _SkillsTab(employee: employee),
                            _DocumentsTab(employee: employee),
                            _HistoryTab(
                              presences: bundle.presences,
                              conges: bundle.conges,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge doc count ────────────────────────────────────────────────────────────


// ── Carte profil ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.employee});
  final Employe employee;

  @override
  Widget build(BuildContext context) {
    final isActif = employee.statut.toUpperCase().contains('ACTIF');

    return GrhSurfaceCard(
      withShadow: true,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          EmployeeAvatar(
            name: employee.fullName,
            imageUrl: employee.photoUrl,
            size: 80,
          ),
          const SizedBox(width: 20),

          // Nom + poste + matricule
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.text1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${employee.poste} – ${employee.service}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.text2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  employee.matricule,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.text2,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),

          // Infos de contact (colonnes)
          if (MediaQuery.sizeOf(context).width >= 860) ...[
            const SizedBox(width: 24),
            Wrap(
              spacing: 32,
              runSpacing: 12,
              children: [
                _ContactInfo(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: employee.email,
                ),
                _ContactInfo(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: employee.telephone ?? 'Non renseigné',
                ),
                _ContactInfo(
                  icon: Icons.calendar_today_outlined,
                  label: "Date d'embauche",
                  value: AppFormatters.shortDate(employee.dateEmbauche),
                ),
                _ContactInfo(
                  icon: Icons.location_on_outlined,
                  label: 'Lieu',
                  value: employee.adresse?.split('\n').first ?? 'Non renseigné',
                ),
              ],
            ),
            const SizedBox(width: 20),
          ],

          // Badge statut + menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(
                    label: employee.statut,
                    type: isActif ? 'success' : 'warning',
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.more_vert_rounded,
                      size: 20, color: AppColors.text2),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  const _ContactInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.text2),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.text2,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.text1,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ── Onglet Informations – grille 3 colonnes ────────────────────────────────────

class _InformationTab extends StatelessWidget {
  const _InformationTab({required this.employee});
  final Employe employee;

  static const _na = 'Non renseigné';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    final leftCol = GrhSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Informations personnelles'),
          const SizedBox(height: 12),
          _InfoRow(
              label: 'Date de naissance',
              value: employee.dateNaissance != null ? AppFormatters.shortDate(employee.dateNaissance) : _na),
          _InfoRow(label: 'Nationalité', value: employee.nationalite ?? _na),
          _InfoRow(label: 'Genre', value: employee.genre ?? _na),
          _InfoRow(label: 'Adresse', value: employee.adresse ?? _na),
          _InfoRow(label: 'E-mail', value: employee.email),
          _InfoRow(label: 'Téléphone', value: employee.telephone ?? _na),
        ],
      ),
    );

    final centerCol = Column(
      children: [
        GrhSurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Informations professionnelles'),
              const SizedBox(height: 12),
              _InfoRow(label: 'Matricule', value: employee.matricule),
              _InfoRow(label: 'Département', value: employee.departement ?? _na),
              _InfoRow(label: 'Service', value: employee.service),
              _InfoRow(label: 'Poste', value: employee.poste),
              _InfoRow(label: 'Type de contrat', value: employee.typeContrat),
              _InfoRow(
                  label: "Date d'embauche",
                  value: employee.dateEmbauche != null ? AppFormatters.shortDate(employee.dateEmbauche) : _na),
              _InfoRowWithBadge(
                label: 'Statut',
                badgeLabel: employee.statut,
                badgeType: employee.statut.toUpperCase() == 'ACTIF' ? 'success' : 'warning',
              ),
              _InfoRow(label: 'Manager', value: employee.managerNom ?? _na),
              _InfoRow(
                  label: 'Salaire de base',
                  value: employee.salaire != null ? AppFormatters.currency(employee.salaire!) : 'Confidentiel'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GrhSurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Compétences'),
              const SizedBox(height: 16),
              EmployeeCompetencesPanel(matricule: employee.matricule),
            ],
          ),
        ),
      ],
    );

    final rightCol = GrhSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: EmployeeDocumentsPanel(matricule: employee.matricule, compact: true),
    );

    if (isWide) {
      return SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: leftCol),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: centerCol),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: rightCol),
          ],
        ),
      );
    }

    return ListView(
      children: [leftCol, const SizedBox(height: 14), centerCol, const SizedBox(height: 14), rightCol],
    );
  }
}

// ── Barre de compétence ────────────────────────────────────────────────────────


// ── Titre de section ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.text1,
      ),
    );
  }
}

// ── Ligne info (label / valeur) ────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.text2)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1)),
          ),
        ],
      ),
    );
  }
}

class _InfoRowWithBadge extends StatelessWidget {
  const _InfoRowWithBadge({
    required this.label,
    required this.badgeLabel,
    required this.badgeType,
  });
  final String label;
  final String badgeLabel;
  final String badgeType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.text2)),
          ),
          StatusBadge(label: badgeLabel, type: badgeType),
        ],
      ),
    );
  }
}

// ── Ligne document ─────────────────────────────────────────────────────────────



// ── Onglet Contrat ─────────────────────────────────────────────────────────────

class _ContractTab extends StatelessWidget {
  const _ContractTab({required this.employee, this.onChanged});
  final Employe employee;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GrhSurfaceCard(
          child: Column(
            children: [
              _InfoRow(label: 'Type de contrat', value: employee.typeContrat),
              _InfoRow(
                  label: 'Date début',
                  value: AppFormatters.shortDate(employee.dateEmbauche)),
              _InfoRow(
                  label: 'Date fin',
                  value: employee.dateFinContrat != null
                      ? AppFormatters.shortDate(employee.dateFinContrat)
                      : 'Indéterminée'),
              _InfoRow(label: 'Poste', value: employee.poste),
              _InfoRow(label: 'Service', value: employee.service),
              _InfoRow(
                  label: 'Salaire brut',
                  value: employee.salaire != null ? AppFormatters.currency(employee.salaire!) : 'Confidentiel'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GrhSurfaceCard(
          child: EmployeeContratsPanel(matricule: employee.matricule, onChanged: onChanged),
        ),
      ],
    );
  }
}

// ── Onglet Paie ────────────────────────────────────────────────────────────────

class _PayrollTab extends ConsumerWidget {
  const _PayrollTab({required this.items});
  final List<FichePaie> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _PlaceholderCard(
        title: 'Aucun bulletin disponible',
        description: 'Les bulletins de paie apparaîtront ici.',
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        return GrhSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.periode,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                            'Salaire net ${AppFormatters.currency(item.salaireNet)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.text2)),
                      ],
                    ),
                  ),
                  StatusBadge(
                      label: item.calculee ? 'Calculé' : 'À valider',
                      type: item.calculee ? 'success' : 'warning'),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PayrollMetric(
                      label: 'Salaire brut',
                      value: AppFormatters.currency(item.salaireBrut)),
                  _PayrollMetric(
                      label: 'Cotisations',
                      value: AppFormatters.currency(item.cotisations)),
                  _PayrollMetric(
                      label: 'Impôts',
                      value: AppFormatters.currency(item.impots)),
                  _PayrollMetric(
                      label: 'Indemnités',
                      value: AppFormatters.currency(item.indemnites)),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final filePath =
                        await ref.read(apiServiceProvider).downloadFile(
                              '/paie/${item.id}/bulletin/pdf',
                              'bulletin-${item.id}.pdf',
                            );
                    if (filePath != null && !kIsWeb) {
                      await OpenFilex.open(filePath);
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Télécharger'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Onglet Compétences ─────────────────────────────────────────────────────────

class _SkillsTab extends StatelessWidget {
  const _SkillsTab({required this.employee});
  final Employe employee;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GrhSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Compétences & niveaux'),
              const SizedBox(height: 16),
              EmployeeCompetencesPanel(matricule: employee.matricule),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Onglet Documents ───────────────────────────────────────────────────────────

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.employee});
  final Employe employee;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GrhSurfaceCard(child: EmployeeDocumentsPanel(matricule: employee.matricule)),
      ],
    );
  }
}

// ── Onglet Historique ──────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.presences, required this.conges});
  final List<Presence> presences;
  final List<Conge> conges;

  @override
  Widget build(BuildContext context) {
    final events = <_HistoryEvent>[
      ...presences.map((item) => _HistoryEvent(
            title: 'Présence ${item.statut}',
            description:
                '${AppFormatters.longDate(item.date)} • Arrivée ${AppFormatters.time(item.heureArrivee)} • Départ ${AppFormatters.time(item.heureDepart)}',
            date: item.date,
            type: item.statut == 'PRESENT' ? 'success' : 'warning',
          )),
      ...conges.map((item) => _HistoryEvent(
            title: 'Congé ${item.typeConge}',
            description:
                '${AppFormatters.shortDate(item.dateDebut)} → ${AppFormatters.shortDate(item.dateFin)} • ${item.nombreJours} jours',
            date: item.dateDebut,
            type: item.statut == 'APPROUVE'
                ? 'success'
                : item.statut == 'EN_ATTENTE'
                    ? 'warning'
                    : 'error',
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (events.isEmpty) {
      return const _PlaceholderCard(
        title: 'Historique vide',
        description: 'Les événements de présence et de congés apparaîtront ici.',
      );
    }

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = events[index];
        return GrhSurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _colorForType(item.type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.schedule_outlined,
                    color: _colorForType(item.type)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(item.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.text2)),
                  ],
                ),
              ),
              StatusBadge(
                  label: AppFormatters.shortDate(item.date),
                  type: item.type),
            ],
          ),
        );
      },
    );
  }
}

// ── Métrique paie ──────────────────────────────────────────────────────────────

class _PayrollMetric extends StatelessWidget {
  const _PayrollMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.text2)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text1)),
        ],
      ),
    );
  }
}

// ── Placeholder ────────────────────────────────────────────────────────────────

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard(
      {required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GrhSurfaceCard(
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 44, color: AppColors.text2),
              const SizedBox(height: 12),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.text2)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

Color _colorForType(String type) => switch (type) {
      'success' => AppColors.success,
      'warning' => AppColors.warning,
      'error' => AppColors.danger,
      _ => AppColors.info,
    };

// ── Modèles internes ───────────────────────────────────────────────────────────

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

class _HistoryEvent {
  const _HistoryEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });
  final String title;
  final String description;
  final DateTime date;
  final String type;
}
