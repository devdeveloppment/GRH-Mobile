import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/departement_provider.dart';
import 'package:grh_mobile/shared/models/departement.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';

class DepartementListScreen extends ConsumerStatefulWidget {
  const DepartementListScreen({super.key});

  @override
  ConsumerState<DepartementListScreen> createState() =>
      _DepartementListScreenState();
}

class _DepartementListScreenState extends ConsumerState<DepartementListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final state = ref.watch(departementNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final canEdit = auth.role?.isHrFamily ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.departements,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Départements',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
            bottom: TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.text2,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Liste'),
                Tab(text: 'Organigramme'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouveau', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Row(
        children: [
          if (isWide)
            GrhSidebar(
              currentRoute: AppRoutes.departements,
              role: auth.role!,
            ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildList(state, canEdit),
                _buildOrganigramme(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AsyncValue<List<Departement>> state, bool canEdit) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (depts) {
        if (depts.isEmpty) {
          return const Center(child: Text('Aucun département'));
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(departementNotifierProvider.notifier).load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: depts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _DeptCard(
              dept: depts[i],
              canEdit: canEdit,
              onEdit: () => _showForm(context, dept: depts[i]),
              onDelete: () => _confirmDelete(depts[i]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrganigramme() {
    final orgAsync = ref.watch(organigrammeProvider);
    return orgAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (roots) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: roots.length,
        itemBuilder: (_, i) => _OrgNode(dept: roots[i], depth: 0),
      ),
    );
  }

  void _showForm(BuildContext context, {Departement? dept}) {
    final depts = ref.read(departementNotifierProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DeptForm(
        dept: dept,
        parents: depts,
        onSave: (body) async {
          final notifier = ref.read(departementNotifierProvider.notifier);
          final ok = dept == null
              ? await notifier.create(body)
              : await notifier.update(dept.id, body);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok ? 'Département enregistré.' : 'Erreur.'),
            ));
          }
        },
      ),
    );
  }

  void _confirmDelete(Departement dept) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Désactiver le département ?'),
        content: Text('Le département "${dept.nom}" sera désactivé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(departementNotifierProvider.notifier).desactiver(dept.id);
            },
            child: const Text('Désactiver', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DeptCard extends StatelessWidget {
  const _DeptCard({
    required this.dept,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final Departement dept;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GrhSurfaceCard(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.account_tree_outlined, color: AppColors.primary),
        ),
        title: Text(dept.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${dept.code}'),
            if (dept.managerNom != null)
              Text('Manager: ${dept.managerNom}',
                  style: const TextStyle(color: AppColors.text2)),
            if (dept.parentNom != null)
              Text('Parent: ${dept.parentNom}',
                  style: const TextStyle(color: AppColors.text2)),
          ],
        ),
        trailing: canEdit
            ? PopupMenuButton<String>(
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  const PopupMenuItem(value: 'delete', child: Text('Désactiver')),
                ],
              )
            : null,
      ),
    );
  }
}

class _OrgNode extends StatelessWidget {
  const _OrgNode({required this.dept, required this.depth});
  final Departement dept;
  final int depth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              dept.sousDepartements.isEmpty
                  ? Icons.circle
                  : Icons.account_tree_outlined,
              color: AppColors.primary,
              size: 18,
            ),
            title: Text(dept.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: dept.managerNom != null
                ? Text('Manager: ${dept.managerNom}')
                : null,
            dense: true,
          ),
          ...dept.sousDepartements
              .map((c) => _OrgNode(dept: c, depth: depth + 1)),
        ],
      ),
    );
  }
}

class _DeptForm extends StatefulWidget {
  const _DeptForm({this.dept, required this.parents, required this.onSave});
  final Departement? dept;
  final List<Departement> parents;
  final void Function(Map<String, dynamic>) onSave;

  @override
  State<_DeptForm> createState() => _DeptFormState();
}

class _DeptFormState extends State<_DeptForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _nom;
  late final TextEditingController _desc;
  int? _parentId;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.dept?.code ?? '');
    _nom = TextEditingController(text: widget.dept?.nom ?? '');
    _desc = TextEditingController(text: widget.dept?.description ?? '');
    _parentId = widget.dept?.parentId;
  }

  @override
  void dispose() {
    _code.dispose();
    _nom.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.dept == null ? 'Nouveau département' : 'Modifier le département',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Code *'),
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nom,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _parentId,
                decoration: const InputDecoration(labelText: 'Département parent'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Aucun (racine)')),
                  ...widget.parents
                      .where((d) => d.id != widget.dept?.id)
                      .map((d) => DropdownMenuItem(value: d.id, child: Text(d.nom))),
                ],
                onChanged: (v) => setState(() => _parentId = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    if (_form.currentState!.validate()) {
                      widget.onSave({
                        'code': _code.text.trim().toUpperCase(),
                        'nom': _nom.text.trim(),
                        'description': _desc.text.trim(),
                        'parentId': _parentId,
                      });
                    }
                  },
                  child: const Text('Enregistrer',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
