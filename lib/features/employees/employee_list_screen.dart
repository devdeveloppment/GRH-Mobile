import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/shared/widgets/temporary_password_dialog.dart';
import 'package:grh_mobile/shared/models/poste.dart';
import 'package:grh_mobile/shared/models/departement.dart';
import 'package:grh_mobile/core/providers/departement_provider.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/employee_provider.dart';
import 'package:grh_mobile/shared/models/employe.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/app_form_field.dart';
import 'package:grh_mobile/shared/widgets/confirm_dialog.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';
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

  // Filtres locaux
  String? _serviceFilter;
  String? _posteFilter;
  String? _statutFilter;

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(employeeNotifierProvider).fetchInitial());
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      ref.read(employeeNotifierProvider).fetchMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(employeeNotifierProvider).setQuery(value);
      setState(() => _currentPage = 1);
    });
  }

  bool get _hasActiveFilters =>
      _serviceFilter != null ||
      _posteFilter != null ||
      _statutFilter != null ||
      _searchController.text.isNotEmpty;

  void _clearFilters() {
    _searchController.clear();
    ref.read(employeeNotifierProvider).setQuery('');
    setState(() {
      _serviceFilter = null;
      _posteFilter = null;
      _statutFilter = null;
      _currentPage = 1;
    });
  }

  List<Employe> _filtered(List<Employe> all) {
    return all.where((e) {
      if (_serviceFilter != null && e.service != _serviceFilter) return false;
      if (_posteFilter != null && e.poste != _posteFilter) return false;
      if (_statutFilter != null &&
          e.statut.toUpperCase() != _statutFilter!.toUpperCase()) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final employees = ref.watch(employeeNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1120;

    final filtered = _filtered(employees.employees);
    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 999);
    final pageItems = filtered
        .skip((_currentPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();

    final services = employees.employees.map((e) => e.service).toSet().toList()..sort();
    const statuts  = ['ACTIF', 'INACTIF', 'EN CONGE'];

    return Scaffold(
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
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Employés',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      floatingActionButton: isWide || !_canCreate(auth.role)
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              onPressed: () => _openEmployeeForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.employees, role: auth.role!),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── En-tête ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Employés',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${employees.employees.length} collaborateur${employees.employees.length > 1 ? 's' : ''} enregistré${employees.employees.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.text2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_canCreate(auth.role))
                        ElevatedButton.icon(
                          onPressed: () => _openEmployeeForm(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Stats ─────────────────────────────────────────────────
                if (employees.employees.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _StatsRow(employees: employees.employees),
                  ),

                // ── Recherche + filtres ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _SearchField(
                                controller: _searchController,
                                onChanged: (v) {
                                  setState(() {});
                                  _onSearchChanged(v);
                                },
                                onClear: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            _FilterDropdown(
                              hint: 'Service',
                              value: _serviceFilter,
                              items: services,
                              onChanged: (v) => setState(() {
                                _serviceFilter = v;
                                _currentPage = 1;
                              }),
                            ),
                            const SizedBox(width: 10),
                            _FilterDropdown(
                              hint: 'Statut',
                              value: _statutFilter,
                              items: statuts,
                              onChanged: (v) => setState(() {
                                _statutFilter = v;
                                _currentPage = 1;
                              }),
                            ),
                            if (_hasActiveFilters) ...[
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Effacer'),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error),
                              ),
                            ],
                          ],
                        )
                      : _SearchField(
                          controller: _searchController,
                          onChanged: (v) {
                            setState(() {});
                            _onSearchChanged(v);
                          },
                          onClear: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {});
                          },
                        ),
                ),

                const SizedBox(height: 16),

                // ── Contenu principal ─────────────────────────────────────
                if (employees.isLoading && employees.employees.isEmpty)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (employees.errorMessage != null &&
                    employees.employees.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              size: 52, color: AppColors.text2),
                          const SizedBox(height: 12),
                          Text(employees.errorMessage!,
                              style: const TextStyle(color: AppColors.text1)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(employeeNotifierProvider)
                                .refresh(),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  Expanded(
                    child: Center(
                      child: _hasActiveFilters
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off_rounded,
                                    size: 52, color: AppColors.text2),
                                const SizedBox(height: 12),
                                const Text(
                                  'Aucun employé ne correspond aux filtres.',
                                  style: TextStyle(
                                      fontSize: 15, color: AppColors.text1),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.close_rounded,
                                      size: 16),
                                  label: const Text('Effacer les filtres'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_outline_rounded,
                                    size: 56, color: AppColors.text2),
                                const SizedBox(height: 12),
                                const Text(
                                  'Aucun employé enregistré.',
                                  style: TextStyle(
                                      fontSize: 15, color: AppColors.text1),
                                ),
                                if (_canCreate(auth.role)) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _openEmployeeForm(context),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text(
                                        'Ajouter le premier employé'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.read(employeeNotifierProvider).refresh(),
                      child: isWide
                          ? SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: Column(
                                children: [
                                  _DesktopEmployeeTable(
                                    employees: pageItems,
                                    canEdit: _canEdit(auth.role),
                                    canArchive: _canArchive(auth.role),
                                    onOpen: (e) => context.go(
                                      '${AppRoutes.employees}/${e.matricule}',
                                      extra: e,
                                    ),
                                    onEdit: (e) =>
                                        _openEmployeeForm(context, employee: e),
                                    onArchive: (e) => _archiveEmployee(e),
                                  ),
                                  if (employees.isFetchingMore)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                  if (totalPages > 1) ...[
                                    const SizedBox(height: 16),
                                    const Divider(color: AppColors.borderLight),
                                    const SizedBox(height: 12),
                                    _PaginationBar(
                                      currentPage: _currentPage,
                                      totalPages: totalPages,
                                      totalItems: filtered.length,
                                      pageSize: _pageSize,
                                      onPageChanged: (p) =>
                                          setState(() => _currentPage = p),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: pageItems.length +
                                  (employees.isFetchingMore ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i == pageItems.length) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final e = pageItems[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _EmployeeMobileCard(employee: e),
                                );
                              },
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

  static bool _canCreate(UserRole? role) =>
      role == UserRole.rhManager || role == UserRole.hrAdmin;
  static bool _canEdit(UserRole? role) =>
      role == UserRole.rhManager || role == UserRole.hrAdmin;
  static bool _canArchive(UserRole? role) =>
      role == UserRole.admin ||
      role == UserRole.rhManager ||
      role == UserRole.hrAdmin;

  Future<void> _archiveEmployee(Employe employee) {
    return ConfirmDialog.show(
      context,
      title: 'Archiver cet employé ?',
      message:
          'Le dossier de ${employee.fullName} sera retiré des listes actives.',
      type: 'danger',
      onConfirm: () => ref
          .read(employeeNotifierProvider)
          .archiveEmployee(employee.matricule),
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

// ── Widget champ de recherche ──────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher un employé...',
          hintStyle: const TextStyle(color: AppColors.text2),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.text2),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Dropdown filtre ────────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: value != null
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value != null ? AppColors.primary : AppColors.border,
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              color: AppColors.text2,
              fontSize: 13,
            ),
          ),
          style: const TextStyle(
            color: AppColors.text1,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: value != null ? AppColors.primary : AppColors.text2,
            size: 18,
          ),
          isDense: true,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Tous — $hint',
                  style: const TextStyle(color: AppColors.text2)),
            ),
            for (final item in items)
              DropdownMenuItem<String>(value: item, child: Text(item)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Tableau desktop ────────────────────────────────────────────────────────────

class _DesktopEmployeeTable extends StatelessWidget {
  const _DesktopEmployeeTable({
    required this.employees,
    required this.canEdit,
    required this.canArchive,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
  });

  final List<Employe> employees;
  final bool canEdit;
  final bool canArchive;
  final ValueChanged<Employe> onOpen;
  final ValueChanged<Employe> onEdit;
  final ValueChanged<Employe> onArchive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête du tableau
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 46), // avatar
              SizedBox(width: 12),
              Expanded(flex: 3, child: Text('Employé',   style: _headerStyle)),
              Expanded(flex: 2, child: Text('Matricule', style: _headerStyle)),
              Expanded(flex: 2, child: Text('Poste',     style: _headerStyle)),
              Expanded(flex: 2, child: Text('Service',   style: _headerStyle)),
              Expanded(flex: 1, child: Text('Statut',    style: _headerStyle)),
              SizedBox(width: 100), // actions
            ],
          ),
        ),
        // Lignes
        ...employees.map((e) => _EmployeeRow(
              employee: e,
              canEdit: canEdit,
              canArchive: canArchive,
              onOpen: onOpen,
              onEdit: onEdit,
              onArchive: onArchive,
            )),
      ],
    );
  }

  static const _headerStyle = TextStyle(
    color: AppColors.text2,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    letterSpacing: 0.2,
  );
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.employee,
    required this.canEdit,
    required this.canArchive,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
  });

  final Employe employee;
  final bool canEdit;
  final bool canArchive;
  final ValueChanged<Employe> onOpen;
  final ValueChanged<Employe> onEdit;
  final ValueChanged<Employe> onArchive;

  @override
  Widget build(BuildContext context) {
    final statut = employee.statut.toUpperCase();
    final statutType = statut.contains('ACTIF')
        ? 'success'
        : statut.contains('CONGE')
            ? 'warning'
            : 'error';

    return InkWell(
      onTap: () => onOpen(employee),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            EmployeeAvatar(
                name: employee.fullName,
                imageUrl: employee.photoUrl,
                size: 40),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                employee.fullName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.text1),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(employee.matricule,
                  style: const TextStyle(color: AppColors.text2, fontSize: 13)),
            ),
            Expanded(
              flex: 2,
              child: Text(employee.poste,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(employee.service,
                  style: const TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                      fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 1,
              child: StatusBadge(label: employee.statut, type: statutType),
            ),
            SizedBox(
              width: 100,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionBtn(
                    icon: Icons.visibility_outlined,
                    color: AppColors.primary,
                    tooltip: 'Voir',
                    onPressed: () => onOpen(employee),
                  ),
                  if (canEdit)
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppColors.accent,
                      tooltip: 'Modifier',
                      onPressed: () => onEdit(employee),
                    ),
                  if (canArchive)
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.error,
                      tooltip: 'Archiver',
                      onPressed: () => onArchive(employee),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ── Pagination ─────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = ((currentPage - 1) * pageSize + 1).clamp(1, totalItems);
    final end = (currentPage * pageSize).clamp(1, totalItems);

    // Génère les numéros à afficher avec ellipses
    final pages = <int?>[];
    if (totalPages <= 7) {
      pages.addAll(List.generate(totalPages, (i) => i + 1));
    } else {
      pages.add(1);
      if (currentPage > 3) pages.add(null); // ellipse
      for (var i = (currentPage - 1).clamp(2, totalPages - 1);
          i <= (currentPage + 1).clamp(2, totalPages - 1);
          i++) {
        pages.add(i);
      }
      if (currentPage < totalPages - 2) pages.add(null); // ellipse
      pages.add(totalPages);
    }

    return Row(
      children: [
        Text(
          '$start–$end sur $totalItems',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
        const Spacer(),
        // Précédent
        _PageBtn(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 4),
        // Numéros
        for (final page in pages)
          if (page == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: TextStyle(color: AppColors.textSecondaryLight)),
            )
          else
            _PageNumberBtn(
              page: page,
              isActive: page == currentPage,
              onTap: () => onPageChanged(page),
            ),
        const SizedBox(width: 4),
        // Suivant
        _PageBtn(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }
}

class _PageNumberBtn extends StatelessWidget {
  const _PageNumberBtn({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  final int page;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.borderLight,
          ),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textPrimaryLight,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.textPrimaryLight : AppColors.borderLight,
          size: 20,
        ),
      ),
    );
  }
}

// ── Carte mobile employé ───────────────────────────────────────────────────────

class _EmployeeMobileCard extends StatelessWidget {
  const _EmployeeMobileCard({required this.employee});

  final Employe employee;

  @override
  Widget build(BuildContext context) {
    return GrhSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(
          '${AppRoutes.employees}/${employee.matricule}',
          extra: employee,
        ),
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
                  Text(
                    employee.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Matricule ${employee.matricule}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(employee.poste)),
                      Chip(label: Text(employee.service)),
                      StatusBadge(
                        label: employee.statut,
                        type: employee.statut.toUpperCase().contains('ACTIF')
                            ? 'success'
                            : 'warning',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}

// ── Bandeau statistiques ───────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.employees});
  final List<Employe> employees;

  @override
  Widget build(BuildContext context) {
    final total = employees.length;
    final actifs = employees
        .where((e) => e.statut.toUpperCase().contains('ACTIF'))
        .length;
    final conge = employees
        .where((e) => e.statut.toUpperCase().contains('CONGE'))
        .length;
    final inactifs = total - actifs - conge;

    return Row(
      children: [
        _StatCard(
          label: 'Total',
          value: total,
          icon: Icons.people_alt_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Actifs',
          value: actifs,
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'En congé',
          value: conge,
          icon: Icons.beach_access_outlined,
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Inactifs',
          value: inactifs,
          icon: Icons.person_off_outlined,
          color: AppColors.error,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GrhSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formulaire employé — stepper 3 étapes ─────────────────────────────────────

class _EmployeeFormSheet extends ConsumerStatefulWidget {
  const _EmployeeFormSheet({this.employee});
  final Employe? employee;

  @override
  ConsumerState<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends ConsumerState<_EmployeeFormSheet> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _loading = false;

  late final TextEditingController _prenom;
  late final TextEditingController _nom;
  late final TextEditingController _email;
  late final TextEditingController _telephone;
  late final TextEditingController _poste;
  late final TextEditingController _service;
  late final TextEditingController _salaire;
  String _typeContrat = 'CDI';
  String _statut = 'ACTIF';
  int? _departementId;
  int? _posteId;
  String? _managerMatricule;

  static const _stepLabels = ['Identité', 'Poste', 'Contrat'];

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _prenom = TextEditingController(text: e?.prenom ?? '');
    _nom = TextEditingController(text: e?.nom ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _telephone = TextEditingController(text: e?.telephone ?? '');
    _poste = TextEditingController(text: e?.poste ?? '');
    _service = TextEditingController(text: e?.service ?? '');
    _salaire = TextEditingController(
        text: e?.salaire != null ? e!.salaire!.toStringAsFixed(0) : '');
    _typeContrat = const ['CDI', 'CDD', 'STAGE'].contains(e?.typeContrat) ? e!.typeContrat : 'CDI';
    _statut = e?.statut ?? 'ACTIF';
    _departementId = e?.departementId;
    _posteId = e?.posteId;
    _managerMatricule = e?.managerMatricule;
  }

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _email, _telephone, _poste, _service, _salaire]) {
      c.dispose();
    }
    super.dispose();
  }

  GlobalKey<FormState> get _currentFormKey =>
      [_step1Key, _step2Key, _step3Key][_currentStep];

  void _next() {
    if (!_currentFormKey.currentState!.validate()) return;
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final existing = widget.employee;
    final payload = {
      // Champs non éditables ici : renvoyés tels quels pour ne pas les effacer
      if (existing != null) ...{
        'dateNaissance': existing.dateNaissance?.toIso8601String().substring(0, 10),
        'genre': existing.genre,
        'nationalite': existing.nationalite,
        'adresse': existing.adresse,
        'dateEmbauche': existing.dateEmbauche?.toIso8601String().substring(0, 10),
        'dateFin': existing.dateFinContrat?.toIso8601String().substring(0, 10),
        'photoUrl': existing.photoUrl,
      },
      'posteId': _posteId,
      'departementId': _departementId,
      'managerMatricule': _managerMatricule,
      'nom': _nom.text.trim(),
      'prenom': _prenom.text.trim(),
      'email': _email.text.trim(),
      'telephone': _telephone.text.trim(),
      'poste': _poste.text.trim(),
      'service': _service.text.trim(),
      'typeContrat': _typeContrat,
      'statut': _statut,
      'salaire': double.tryParse(_salaire.text.trim().replaceAll(' ', '')) ?? 0,
    };
    try {
      bool success = false;
      if (widget.employee != null) {
        success = await ref.read(employeeNotifierProvider).updateEmployee(
              widget.employee!.matricule, payload);
      } else {
        success = await ref.read(employeeNotifierProvider).createEmployee(payload);
      }
      
      if (mounted) {
        if (success) {
          final tempPassword = ref.read(employeeNotifierProvider).lastTemporaryPassword;
          final createdEmail = _email.text.trim();
          final navigator = Navigator.of(context);
          final rootContext = navigator.context;
          navigator.pop();
          if (tempPassword != null && rootContext.mounted) {
            await showTemporaryPasswordDialog(rootContext, email: createdEmail, password: tempPassword);
          }
        } else {
          final errorMsg = ref.read(employeeNotifierProvider).errorMessage ?? 'Une erreur est survenue';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.error,
            content: Text(errorMsg),
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Poignée + en-tête ──
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_outlined : Icons.person_add_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Modifier le collaborateur' : 'Nouveau collaborateur',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text1),
                          ),
                          Text(
                            'Étape ${_currentStep + 1} sur 3 — ${_stepLabels[_currentStep]}',
                            style: const TextStyle(fontSize: 12, color: AppColors.text2),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppStepIndicator(
                    currentStep: _currentStep,
                    totalSteps: 3,
                    labels: _stepLabels,
                  ),
                ],
              ),
            ),

            // ── Contenu de l'étape ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: _buildStep(),
                  ),
                ),
              ),
            ),

            // ── Boutons navigation ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              color: Colors.white,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _back,
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                        label: const Text('Retour'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: AppColors.text1,
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _next,
                      icon: _loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(_currentStep < 2 ? Icons.arrow_forward_ios_rounded : Icons.check_rounded, size: 16),
                      label: Text(_currentStep < 2 ? 'Suivant' : (isEditing ? 'Enregistrer' : "Créer l'employé")),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _step1Key,
          child: AppFormSection(
            title: 'Identité',
            subtitle: 'Informations personnelles du collaborateur',
            icon: Icons.person_outline_rounded,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppFormField(
                      controller: _prenom,
                      label: 'Prénom *',
                      prefixIcon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppFormField(
                      controller: _nom,
                      label: 'Nom *',
                      prefixIcon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _email,
                label: 'Adresse e-mail *',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v ?? '').contains('@') ? null : 'E-mail invalide',
                helperText: 'Servira d\'identifiant de connexion',
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _telephone,
                label: 'Téléphone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _step2Key,
          child: AppFormSection(
            title: 'Poste & Organisation',
            subtitle: 'Rôle et rattachement hiérarchique',
            icon: Icons.work_outline_rounded,
            children: [
              _OrganisationPickers(
                departementId: _departementId,
                posteId: _posteId,
                managerMatricule: _managerMatricule,
                excludeMatricule: widget.employee?.matricule,
                onDepartement: (id) => setState(() {
                  _departementId = id;
                }),
                onPoste: (poste) => setState(() {
                  _posteId = poste?.id;
                  if (poste != null) _poste.text = poste.intitule;
                  if (poste?.departementId != null) _departementId = poste!.departementId;
                }),
                onManager: (m) => setState(() => _managerMatricule = m),
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _poste,
                label: 'Intitulé du poste *',
                prefixIcon: Icons.work_outline,
                textCapitalization: TextCapitalization.words,
                helperText: 'Rempli automatiquement si un poste du référentiel est choisi',
                validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _service,
                label: 'Service *',
                prefixIcon: Icons.business_outlined,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              AppDropdownField<String>(
                label: 'Statut',
                value: _statut,
                prefixIcon: Icons.toggle_on_outlined,
                items: const [
                  DropdownMenuItem(value: 'ACTIF', child: Text('Actif')),
                  DropdownMenuItem(value: 'INACTIF', child: Text('Inactif')),
                  DropdownMenuItem(value: 'EN CONGE', child: Text('En congé')),
                ],
                onChanged: (v) => setState(() => _statut = v ?? 'ACTIF'),
              ),
            ],
          ),
        );
      case 2:
      default:
        return Form(
          key: _step3Key,
          child: AppFormSection(
            title: 'Contrat & Rémunération',
            subtitle: 'Type de contrat et salaire brut',
            icon: Icons.description_outlined,
            children: [
              AppDropdownField<String>(
                label: 'Type de contrat *',
                value: _typeContrat,
                prefixIcon: Icons.article_outlined,
                items: const [
                  DropdownMenuItem(value: 'CDI', child: Text('CDI — Contrat à Durée Indéterminée')),
                  DropdownMenuItem(value: 'CDD', child: Text('CDD — Contrat à Durée Déterminée')),
                  DropdownMenuItem(value: 'STAGE', child: Text('Stage / Alternance')),
                ],
                onChanged: (v) => setState(() => _typeContrat = v ?? 'CDI'),
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _salaire,
                label: 'Salaire brut mensuel *',
                prefixIcon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                helperText: 'Montant en FCFA',
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return 'Requis';
                  return double.tryParse(v!.trim().replaceAll(' ', '')) == null
                      ? 'Montant invalide'
                      : null;
                },
              ),
            ],
          ),
        );
    }
  }
}

/// Rattachement au référentiel : département, poste et manager (facultatifs).
class _OrganisationPickers extends ConsumerWidget {
  const _OrganisationPickers({
    required this.departementId,
    required this.posteId,
    required this.managerMatricule,
    required this.excludeMatricule,
    required this.onDepartement,
    required this.onPoste,
    required this.onManager,
  });

  final int? departementId;
  final int? posteId;
  final String? managerMatricule;
  final String? excludeMatricule;
  final ValueChanged<int?> onDepartement;
  final ValueChanged<Poste?> onPoste;
  final ValueChanged<String?> onManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departements = ref.watch(departementsProvider).valueOrNull ?? const <Departement>[];
    final postes = ref.watch(_postesListProvider).valueOrNull ?? const <Poste>[];
    final managers = ref.watch(_managerCandidatesProvider).valueOrNull ?? const <Employe>[];

    final visiblePostes = departementId == null
        ? postes
        : postes.where((p) => p.departementId == null || p.departementId == departementId).toList();
    final managerOptions = managers.where((m) => m.matricule != excludeMatricule).toList();

    return Column(
      children: [
        AppDropdownField<int?>(
          label: 'Département',
          value: departements.any((d) => d.id == departementId) ? departementId : null,
          prefixIcon: Icons.account_tree_outlined,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('— Aucun —')),
            for (final d in departements) DropdownMenuItem<int?>(value: d.id, child: Text(d.nom)),
          ],
          onChanged: onDepartement,
        ),
        const SizedBox(height: 14),
        AppDropdownField<int?>(
          label: 'Poste (référentiel)',
          value: visiblePostes.any((p) => p.id == posteId) ? posteId : null,
          prefixIcon: Icons.work_history_outlined,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('— Saisie libre —')),
            for (final p in visiblePostes) DropdownMenuItem<int?>(value: p.id, child: Text(p.intitule)),
          ],
          onChanged: (id) => onPoste(id == null ? null : visiblePostes.firstWhere((p) => p.id == id)),
        ),
        const SizedBox(height: 14),
        AppDropdownField<String?>(
          label: 'Manager',
          value: managerOptions.any((m) => m.matricule == managerMatricule) ? managerMatricule : null,
          prefixIcon: Icons.supervisor_account_outlined,
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('— Aucun —')),
            for (final m in managerOptions)
              DropdownMenuItem<String?>(value: m.matricule, child: Text('${m.fullName} (${m.matricule})')),
          ],
          onChanged: onManager,
        ),
      ],
    );
  }
}

final _postesListProvider = FutureProvider.autoDispose<List<Poste>>((ref) async {
  final resp = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/postes');
  final raw = resp.data?['items'] as List? ?? const [];
  return raw.whereType<Map<String, dynamic>>().map(Poste.fromJson).toList();
});

/// Employés actifs pouvant être désignés comme manager.
final _managerCandidatesProvider = FutureProvider.autoDispose<List<Employe>>((ref) async {
  final resp = await ref.read(apiServiceProvider).get<Map<String, dynamic>>(
    '/employees',
    queryParameters: {'page': 1, 'limit': 200, 'statut': 'ACTIF'},
  );
  final raw = resp.data?['items'] as List? ?? const [];
  return raw.whereType<Map<String, dynamic>>().map(Employe.fromJson).toList();
});
