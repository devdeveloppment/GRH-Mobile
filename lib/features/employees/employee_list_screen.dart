import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/employee_provider.dart';
import 'package:grh_mobile/shared/models/employe.dart';
import 'package:grh_mobile/shared/widgets/confirm_dialog.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 240) {
      ref.read(employeeNotifierProvider).fetchMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(employeeNotifierProvider).setQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final employees = ref.watch(employeeNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.employees,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: GrhAppBar(
          title: 'Employés',
          userName: auth.user?.fullName,
          onMenuTap: isWide ? null : () => Scaffold.of(context).openDrawer(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        onPressed: () => _openEmployeeForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.employees, role: auth.role!),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(employeeNotifierProvider).refresh(),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  SearchBar(
                    controller: _searchController,
                    hintText: 'Rechercher un employé, un matricule ou un poste',
                    leading: const Icon(Icons.search_rounded),
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {});
                      _onSearchChanged(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final service in employees.availableServices)
                        FilterChip(
                          label: Text(service),
                          selected: employees.serviceFilter == service,
                          onSelected: (_) => ref.read(employeeNotifierProvider).setServiceFilter(service),
                        ),
                      for (final status in employees.availableStatuses)
                        FilterChip(
                          label: Text(status),
                          selected: employees.statusFilter == status,
                          onSelected: (_) => ref.read(employeeNotifierProvider).setStatusFilter(status),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (employees.isLoading && employees.employees.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (employees.employees.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          'Aucun employé ne correspond aux filtres actifs.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  else
                    ...employees.employees.map((employee) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Dismissible(
                          key: ValueKey(employee.matricule),
                          background: _SwipeActionBackground(
                            color: AppColors.info,
                            icon: Icons.edit_outlined,
                            alignment: Alignment.centerLeft,
                            label: 'Modifier',
                          ),
                          secondaryBackground: _SwipeActionBackground(
                            color: AppColors.danger,
                            icon: Icons.archive_outlined,
                            alignment: Alignment.centerRight,
                            label: 'Archiver',
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              _openEmployeeForm(context, employee: employee);
                              return false;
                            }

                            await ConfirmDialog.show(
                              context,
                              title: 'Archiver cet employé ?',
                              message: 'Le dossier de ${employee.fullName} sera retiré des listes actives.',
                              type: 'danger',
                              onConfirm: () => ref.read(employeeNotifierProvider).archiveEmployee(employee.matricule),
                            );
                            return false;
                          },
                          child: _EmployeeCard(employee: employee),
                        ),
                      );
                    }),
                  if (employees.isFetchingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEmployeeForm(BuildContext context, {Employe? employee}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EmployeeFormSheet(employee: employee),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});

  final Employe employee;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go('${AppRoutes.employees}/${employee.matricule}', extra: employee),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              EmployeeAvatar(
                name: employee.fullName,
                imageUrl: employee.photoUrl,
                size: 54,
                showStatus: true,
                isOnline: employee.presentAujourdHui ?? false,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          employee.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        StatusBadge(
                          label: employee.typeContrat,
                          type: employee.typeContrat == 'CDI' ? 'success' : 'warning',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Matricule ${employee.matricule}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(employee.poste)),
                        Chip(label: Text(employee.service)),
                        StatusBadge(
                          label: employee.statut,
                          type: employee.statut == 'ACTIF' ? 'success' : 'neutral',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.chevron_right_rounded),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: (employee.presentAujourdHui ?? false) ? AppColors.success : AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text((employee.presentAujourdHui ?? false) ? 'Présent' : 'Absent'),
                    ],
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

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.color,
    required this.icon,
    required this.alignment,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment:
            alignment == Alignment.centerLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (alignment == Alignment.centerRight) Text(label),
          const SizedBox(width: 8),
          Icon(icon, color: color),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 8),
            Text(label),
          ],
        ],
      ),
    );
  }
}

class _EmployeeFormSheet extends ConsumerStatefulWidget {
  const _EmployeeFormSheet({this.employee});

  final Employe? employee;

  @override
  ConsumerState<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends ConsumerState<_EmployeeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _emailController;
  late final TextEditingController _posteController;
  late final TextEditingController _serviceController;
  late final TextEditingController _salaireController;
  String _typeContrat = 'CDI';

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    _nomController = TextEditingController(text: employee?.nom ?? '');
    _prenomController = TextEditingController(text: employee?.prenom ?? '');
    _emailController = TextEditingController(text: employee?.email ?? '');
    _posteController = TextEditingController(text: employee?.poste ?? '');
    _serviceController = TextEditingController(text: employee?.service ?? '');
    _salaireController = TextEditingController(
      text: employee?.salaire != null ? employee!.salaire!.toStringAsFixed(0) : '',
    );
    _typeContrat = employee?.typeContrat ?? 'CDI';
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _posteController.dispose();
    _serviceController.dispose();
    _salaireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Modifier un employé' : 'Ajouter un employé',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (value) => (value ?? '').isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) => (value ?? '').isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (value) => (value ?? '').contains('@') ? null : 'E-mail invalide',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _posteController,
                  decoration: const InputDecoration(labelText: 'Poste'),
                  validator: (value) => (value ?? '').isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _serviceController,
                  decoration: const InputDecoration(labelText: 'Service'),
                  validator: (value) => (value ?? '').isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _salaireController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Salaire brut de base'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Champ requis';
                    }
                    return double.tryParse(value!.trim().replaceAll(' ', '')) == null
                        ? 'Montant invalide'
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _typeContrat,
                  decoration: const InputDecoration(labelText: 'Type de contrat'),
                  items: const [
                    DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                    DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                  ],
                  onChanged: (value) => setState(() => _typeContrat = value ?? 'CDI'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      final payload = {
                        'nom': _nomController.text.trim(),
                        'prenom': _prenomController.text.trim(),
                        'email': _emailController.text.trim(),
                        'poste': _posteController.text.trim(),
                        'service': _serviceController.text.trim(),
                        'typeContrat': _typeContrat,
                        'statut': 'ACTIF',
                        'salaire': double.parse(_salaireController.text.trim().replaceAll(' ', '')),
                      };
                      if (isEditing) {
                        await ref.read(employeeNotifierProvider).updateEmployee(
                              widget.employee!.matricule,
                              payload,
                            );
                      } else {
                        await ref.read(employeeNotifierProvider).createEmployee(payload);
                      }
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(isEditing ? 'Enregistrer' : 'Créer'),
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
