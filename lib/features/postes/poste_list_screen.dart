import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/departement_provider.dart';
import 'package:grh_mobile/core/providers/poste_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/departement.dart';
import 'package:grh_mobile/shared/models/poste.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';

class PosteListScreen extends ConsumerWidget {
  const PosteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final state = ref.watch(posteNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final canEdit = auth.role?.isHrFamily ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.postes,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Postes',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context, ref),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouveau poste', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Row(
        children: [
          if (isWide)
            GrhSidebar(currentRoute: AppRoutes.postes, role: auth.role!),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (postes) {
                if (postes.isEmpty) {
                  return const Center(child: Text('Aucun poste créé'));
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(posteNotifierProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: postes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PosteCard(
                      poste: postes[i],
                      canEdit: canEdit,
                      onEdit: () => _showForm(context, ref, poste: postes[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, {Poste? poste}) {
    final depts = ref.read(departementNotifierProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PosteForm(
        poste: poste,
        departements: depts,
        onSave: (body) async {
          final notifier = ref.read(posteNotifierProvider.notifier);
          final ok = poste == null
              ? await notifier.create(body)
              : await notifier.update(poste.id, body);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ok ? 'Poste enregistré.' : 'Erreur.')),
            );
          }
        },
      ),
    );
  }
}

class _PosteCard extends StatelessWidget {
  const _PosteCard({required this.poste, required this.canEdit, required this.onEdit});
  final Poste poste;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GrhSurfaceCard(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.work_outline, color: AppColors.accent),
        ),
        title: Text(poste.intitule,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${poste.code}'),
            if (poste.departementNom != null)
              Text('Département: ${poste.departementNom}'),
            if (poste.niveau != null) Text('Niveau: ${poste.niveau}'),
            if (poste.salaireMin != null && poste.salaireMax != null)
              Text(
                'Grille: ${AppFormatters.currency(poste.salaireMin!)} – ${AppFormatters.currency(poste.salaireMax!)}',
                style: const TextStyle(color: AppColors.text2, fontSize: 12),
              ),
          ],
        ),
        trailing: canEdit
            ? IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              )
            : null,
        isThreeLine: true,
      ),
    );
  }
}

class _PosteForm extends StatefulWidget {
  const _PosteForm({
    this.poste,
    required this.departements,
    required this.onSave,
  });
  final Poste? poste;
  final List<Departement> departements;
  final void Function(Map<String, dynamic>) onSave;

  @override
  State<_PosteForm> createState() => _PosteFormState();
}

class _PosteFormState extends State<_PosteForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _intitule;
  late final TextEditingController _niveau;
  late final TextEditingController _desc;
  late final TextEditingController _min;
  late final TextEditingController _max;
  int? _departementId;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.poste?.code ?? '');
    _intitule = TextEditingController(text: widget.poste?.intitule ?? '');
    _niveau = TextEditingController(text: widget.poste?.niveau ?? '');
    _desc = TextEditingController(text: widget.poste?.description ?? '');
    _min = TextEditingController(text: widget.poste?.salaireMin?.toString() ?? '');
    _max = TextEditingController(text: widget.poste?.salaireMax?.toString() ?? '');
    _departementId = widget.poste?.departementId;
  }

  @override
  void dispose() {
    for (final c in [_code, _intitule, _niveau, _desc, _min, _max]) c.dispose();
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
                widget.poste == null ? 'Nouveau poste' : 'Modifier le poste',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Code *'),
                validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _intitule,
                decoration: const InputDecoration(labelText: 'Intitulé *'),
                validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _departementId,
                decoration: const InputDecoration(labelText: 'Département'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Non rattaché')),
                  ...widget.departements.map(
                    (d) => DropdownMenuItem(value: d.id, child: Text(d.nom)),
                  ),
                ],
                onChanged: (v) => setState(() => _departementId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _niveau,
                decoration: const InputDecoration(
                    labelText: 'Niveau (ex: JUNIOR, SENIOR, LEAD)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _min,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Salaire min'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _max,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Salaire max'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
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
                        'intitule': _intitule.text.trim(),
                        'departementId': _departementId,
                        'niveau': _niveau.text.trim().toUpperCase().isEmpty
                            ? null
                            : _niveau.text.trim().toUpperCase(),
                        'salaireMin': double.tryParse(_min.text),
                        'salaireMax': double.tryParse(_max.text),
                        'description': _desc.text.trim(),
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
