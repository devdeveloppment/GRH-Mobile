import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/employee_provider.dart';
import 'package:grh_mobile/shared/models/employe.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
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

    // Listes uniques pour les dropdowns
    final services = employees.employees.map((e) => e.service).toSet().toList()
      ..sort();
    final postes = employees.employees.map((e) => e.poste).toSet().toList()
      ..sort();
    final statuts = ['ACTIF', 'INACTIF', 'EN CONGE'];

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
        preferredSize: const Size.fromHeight(84),
        child: Builder(
          builder: (scaffoldContext) => GrhAppBar(
            title: 'Employés',
            userName: auth.user?.fullName,
            onMenuTap:
                isWide ? null : () => Scaffold.of(scaffoldContext).openDrawer(),
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
            child: RefreshIndicator(
              onRefresh: () => ref.read(employeeNotifierProvider).refresh(),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // ── En-tête + boutons ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Employés',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Gérez les informations et les profils des employés',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      if (isWide) ...[
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Export CSV préparé (prochaine itération).'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_outline_rounded),
                          label: const Text('Exporter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text1,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        if (_canCreate(auth.role)) ...[
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _openEmployeeForm(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Ajouter un employé'),
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
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Carte principale ──
                  GrhSurfaceCard(
                    withShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barre recherche + filtres
                        if (isWide)
                          Row(
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
                              const SizedBox(width: 12),
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
                                hint: 'Poste',
                                value: _posteFilter,
                                items: postes,
                                onChanged: (v) => setState(() {
                                  _posteFilter = v;
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
                              if (_serviceFilter != null ||
                                  _posteFilter != null ||
                                  _statutFilter != null) ...[
                                const SizedBox(width: 10),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _serviceFilter = null;
                                    _posteFilter = null;
                                    _statutFilter = null;
                                    _currentPage = 1;
                                  }),
                                  icon: const Icon(Icons.close_rounded,
                                      size: 16),
                                  label: const Text('Effacer'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error),
                                ),
                              ],
                            ],
                          )
                        else
                          _SearchField(
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

                        // Filtres mobile (chips)
                        if (!isWide) ...[
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final service in services)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(service),
                                      selected: _serviceFilter == service,
                                      onSelected: (_) => setState(() {
                                        _serviceFilter = _serviceFilter == service
                                            ? null
                                            : service;
                                        _currentPage = 1;
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Contenu tableau / liste
                        if (employees.isLoading && employees.employees.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded,
                                      size: 48,
                                      color: AppColors.textSecondaryLight),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucun employé ne correspond aux filtres actifs.',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (isWide)
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
                          )
                        else
                          ...pageItems.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Dismissible(
                                key: ValueKey(e.matricule),
                                background: _canEdit(auth.role)
                                    ? const _SwipeActionBackground(
                                        color: AppColors.info,
                                        icon: Icons.edit_outlined,
                                        alignment: Alignment.centerLeft,
                                        label: 'Modifier',
                                      )
                                    : const SizedBox.shrink(),
                                secondaryBackground: _canArchive(auth.role)
                                    ? const _SwipeActionBackground(
                                        color: AppColors.danger,
                                        icon: Icons.archive_outlined,
                                        alignment: Alignment.centerRight,
                                        label: 'Archiver',
                                      )
                                    : const SizedBox.shrink(),
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.startToEnd) {
                                    if (_canEdit(auth.role)) {
                                      _openEmployeeForm(context, employee: e);
                                    }
                                    return false;
                                  }
                                  if (_canArchive(auth.role)) {
                                    await _archiveEmployee(e);
                                  }
                                  return false;
                                },
                                child: _EmployeeMobileCard(employee: e),
                              ),
                            ),
                          ),

                        if (employees.isFetchingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          ),

                        // ── Pagination ──
                        if (filtered.isNotEmpty && totalPages > 1) ...[
                          const SizedBox(height: 20),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _canCreate(UserRole? role) => role == UserRole.rhManager;
  static bool _canEdit(UserRole? role) => role == UserRole.rhManager;
  static bool _canArchive(UserRole? role) =>
      role == UserRole.admin || role == UserRole.rhManager;

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
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
          headingTextStyle: const TextStyle(
            color: AppColors.text2,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
          dataRowMinHeight: 68,
          dataRowMaxHeight: 68,
          dividerThickness: 0.8,
          horizontalMargin: 20,
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Employé')),
            DataColumn(label: Text('Matricule')),
            DataColumn(label: Text('Poste')),
            DataColumn(label: Text('Service')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: [
            for (final employee in employees)
              DataRow(
                onSelectChanged: (_) => onOpen(employee),
                cells: [
                  // Employé (avatar + nom + email)
                  DataCell(
                    Row(
                      children: [
                        EmployeeAvatar(
                          name: employee.fullName,
                          imageUrl: employee.photoUrl,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          employee.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  // Matricule
                  DataCell(
                    Text(
                      employee.matricule,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.text2,
                          ),
                    ),
                  ),
                  // Poste
                  DataCell(
                    Text(
                      employee.poste,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  // Service
                  DataCell(
                    Text(
                      employee.service,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  // Statut
                  DataCell(
                    StatusBadge(
                      label: employee.statut,
                      type: _statutType(employee.statut),
                    ),
                  ),
                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionBtn(
                          icon: Icons.visibility_outlined,
                          color: AppColors.primary,
                          tooltip: 'Voir le dossier',
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
          ],
        ),
    );
  }

  String _statutType(String statut) {
    final s = statut.toUpperCase();
    if (s.contains('ACTIF')) return 'success';
    if (s.contains('CONGE')) return 'warning';
    return 'error';
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

// ── Fond swipe mobile ──────────────────────────────────────────────────────────

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
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
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

// ── Formulaire employé ─────────────────────────────────────────────────────────

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
      text: employee?.salaire != null
          ? employee!.salaire!.toStringAsFixed(0)
          : '',
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
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Poignée
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  isEditing ? 'Modifier un employé' : 'Ajouter un employé',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Renseignez les informations principales du collaborateur.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (v) => (v ?? '').isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v ?? '').isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) =>
                      (v ?? '').contains('@') ? null : 'E-mail invalide',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _posteController,
                  decoration: const InputDecoration(labelText: 'Poste'),
                  validator: (v) => (v ?? '').isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _serviceController,
                  decoration:
                      const InputDecoration(labelText: 'Département / service'),
                  validator: (v) => (v ?? '').isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _salaireController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Salaire brut de base'),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Champ requis';
                    return double.tryParse(v!.trim().replaceAll(' ', '')) == null
                        ? 'Montant invalide'
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _typeContrat,
                  decoration:
                      const InputDecoration(labelText: 'Type de contrat'),
                  items: const [
                    DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                    DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                  ],
                  onChanged: (v) => setState(() => _typeContrat = v ?? 'CDI'),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final payload = {
                        'nom': _nomController.text.trim(),
                        'prenom': _prenomController.text.trim(),
                        'email': _emailController.text.trim(),
                        'poste': _posteController.text.trim(),
                        'service': _serviceController.text.trim(),
                        'typeContrat': _typeContrat,
                        'statut': 'ACTIF',
                        'salaire': double.parse(
                            _salaireController.text.trim().replaceAll(' ', '')),
                      };
                      if (isEditing) {
                        await ref.read(employeeNotifierProvider).updateEmployee(
                              widget.employee!.matricule,
                              payload,
                            );
                      } else {
                        await ref
                            .read(employeeNotifierProvider)
                            .createEmployee(payload);
                      }
                      if (mounted) Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isEditing ? 'Enregistrer' : "Créer l'employé"),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
