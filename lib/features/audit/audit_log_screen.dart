import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';

final _auditLogsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, _AuditFilter>((ref, filter) async {
  final api = ref.read(apiServiceProvider);
  final params = <String, dynamic>{
    'page': filter.page,
    'size': 20,
    if (filter.entite != null) 'entite': filter.entite,
    if (filter.action != null) 'action': filter.action,
    if (filter.acteur != null) 'acteur': filter.acteur,
  };
  final resp = await api.get<Map<String, dynamic>>('/audit-logs', queryParameters: params);
  final raw = resp.data?['items'] as List? ?? [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

class _AuditFilter {
  const _AuditFilter({
    this.page = 0,
    this.entite,
    this.action,
    this.acteur,
  });

  final int page;
  final String? entite;
  final String? action;
  final String? acteur;

  _AuditFilter copyWith({int? page, String? entite, String? action, String? acteur}) =>
      _AuditFilter(
        page: page ?? this.page,
        entite: entite,
        action: action,
        acteur: acteur,
      );

  @override
  bool operator ==(Object other) =>
      other is _AuditFilter &&
      other.page == page &&
      other.entite == entite &&
      other.action == action &&
      other.acteur == acteur;

  @override
  int get hashCode => Object.hash(page, entite, action, acteur);
}

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  _AuditFilter _filter = const _AuditFilter();
  final _acteurCtrl = TextEditingController();

  static const _actions = [null, 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT'];
  static const _entities = [null, 'Employe', 'Conge', 'Paie', 'Evaluation', 'Contrat', 'Formation'];

  @override
  void dispose() {
    _acteurCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final logsAsync = ref.watch(_auditLogsProvider(_filter));
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.auditLog,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Journal d\'audit',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide)
            GrhSidebar(currentRoute: AppRoutes.auditLog, role: auth.role!),
          Expanded(
            child: Column(
              children: [
                _buildFilters(context),
                Expanded(
                  child: logsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
                    data: (logs) => logs.isEmpty
                        ? const Center(child: Text('Aucune entrée d\'audit'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: logs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _AuditCard(log: logs[i]),
                          ),
                  ),
                ),
                if (logsAsync.valueOrNull?.length == 20)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_filter.page > 0)
                          TextButton(
                            onPressed: () => setState(
                                () => _filter = _filter.copyWith(page: _filter.page - 1)),
                            child: const Text('Précédent'),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Page ${_filter.page + 1}'),
                        ),
                        TextButton(
                          onPressed: () => setState(
                              () => _filter = _filter.copyWith(page: _filter.page + 1)),
                          child: const Text('Suivant'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String?>(
              value: _filter.action,
              decoration: const InputDecoration(
                labelText: 'Action',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _actions
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a ?? 'Toutes'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _filter = _filter.copyWith(action: v, page: 0)),
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String?>(
              value: _filter.entite,
              decoration: const InputDecoration(
                labelText: 'Entité',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _entities
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e ?? 'Toutes'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _filter = _filter.copyWith(entite: v, page: 0)),
            ),
          ),
          SizedBox(
            width: 180,
            child: TextField(
              controller: _acteurCtrl,
              decoration: InputDecoration(
                labelText: 'Acteur (email)',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: _acteurCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _acteurCtrl.clear();
                          setState(() => _filter = _filter.copyWith(acteur: null, page: 0));
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => setState(
                  () => _filter = _filter.copyWith(acteur: v.isEmpty ? null : v, page: 0)),
            ),
          ),
          if (_filter.entite != null || _filter.action != null || _filter.acteur != null)
            TextButton.icon(
              onPressed: () {
                _acteurCtrl.clear();
                setState(() => _filter = const _AuditFilter());
              },
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Réinitialiser'),
            ),
        ],
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.log});
  final Map<String, dynamic> log;

  static const _actionColors = {
    'CREATE': Colors.green,
    'UPDATE': Colors.blue,
    'DELETE': Colors.red,
    'LOGIN': Colors.purple,
    'LOGOUT': Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    final action = log['action'] as String? ?? '';
    final color = _actionColors[action] ?? Colors.grey;
    final entite = log['entite'] as String? ?? '';
    final acteur = log['acteurEmail'] as String? ?? log['acteur'] as String? ?? '';
    final createdAt = log['createdAt'] as String? ?? '';
    final entiteId = log['entiteId'];
    final ipAddress = log['ipAddress'] as String?;

    return GrhSurfaceCard(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Text(
            action.isNotEmpty ? action[0] : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        // Wrap : les libellés d'action longs passent à la ligne sur mobile au lieu de déborder.
        title: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                action,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              entite + (entiteId != null ? ' #$entiteId' : ''),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(acteur, style: const TextStyle(fontSize: 12, color: AppColors.text2)),
            Text(createdAt, style: const TextStyle(fontSize: 11, color: AppColors.text2)),
            if (ipAddress != null)
              Text('IP: $ipAddress', style: const TextStyle(fontSize: 11, color: AppColors.text2)),
          ],
        ),
        children: [
          if (log['avant'] != null || log['apres'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (log['avant'] != null) ...[
                    const Text('Avant:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _JsonBox(json: log['avant'].toString()),
                    const SizedBox(height: 8),
                  ],
                  if (log['apres'] != null) ...[
                    const Text('Après:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _JsonBox(json: log['apres'].toString()),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _JsonBox extends StatelessWidget {
  const _JsonBox({required this.json});
  final String json;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        json,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
