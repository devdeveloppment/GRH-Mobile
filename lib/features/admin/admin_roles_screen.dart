import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/permission_provider.dart';
import 'package:grh_mobile/shared/models/permission_model.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';

class AdminRolesScreen extends ConsumerStatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  ConsumerState<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends ConsumerState<AdminRolesScreen> {
  // pendingRoles[permCode] = Set of currently-checked roles
  final Map<String, Set<String>> _pending = {};
  // tracks which permissions are currently saving
  final Set<String> _saving = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPending();
  }

  void _syncPending() {
    final perms = ref.read(permissionNotifierProvider).permissions;
    for (final p in perms) {
      _pending.putIfAbsent(p.code, () => Set<String>.from(p.roles));
    }
  }

  bool _isDirty(AppPermission p) {
    final current = _pending[p.code] ?? {};
    final original = Set<String>.from(p.roles);
    return !current.containsAll(original) ||
        !original.containsAll(current);
  }

  void _toggle(String code, String role, bool checked) {
    setState(() {
      final set = _pending.putIfAbsent(code, () => {});
      if (checked) {
        set.add(role);
      } else {
        set.remove(role);
      }
    });
  }

  Future<void> _save(AppPermission perm) async {
    setState(() => _saving.add(perm.code));
    final roles = (_pending[perm.code] ?? {}).toList();
    final ok = await ref
        .read(permissionNotifierProvider)
        .updateRoles(perm.code, roles);
    if (!mounted) return;
    setState(() => _saving.remove(perm.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Rôles de « ${perm.label} » mis à jour.'
            : ref.read(permissionNotifierProvider).errorMessage ??
                'Erreur lors de la mise à jour.'),
        backgroundColor: ok ? null : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final prov = ref.watch(permissionNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    // Sync pending map when permissions load for the first time
    if (_pending.isEmpty && prov.permissions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(_syncPending);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.adminRoles,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Rôles & Permissions',
            userName: auth.user?.fullName,
            onMenuTap:
                isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(
                currentRoute: AppRoutes.adminRoles, role: auth.role!),
          Expanded(child: _body(prov, isWide)),
        ],
      ),
    );
  }

  Widget _body(dynamic prov, bool isWide) {
    if (prov.isLoading && prov.permissions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prov.errorMessage != null && prov.permissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: AppColors.error, size: 40),
            const SizedBox(height: 10),
            Text(prov.errorMessage!,
                style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(permissionNotifierProvider).loadPermissions(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final permissions =
        (prov.permissions as List).cast<AppPermission>();

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: permissions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final perm = permissions[index];
        return _PermissionCard(
          permission: perm,
          pendingRoles: _pending[perm.code] ?? Set<String>.from(perm.roles),
          isSaving: _saving.contains(perm.code),
          isDirty: _isDirty(perm),
          onToggle: (role, checked) => _toggle(perm.code, role, checked),
          onSave: () => _save(perm),
        );
      },
    );
  }
}

// ── Carte d'une permission ─────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.permission,
    required this.pendingRoles,
    required this.isSaving,
    required this.isDirty,
    required this.onToggle,
    required this.onSave,
  });

  final AppPermission permission;
  final Set<String> pendingRoles;
  final bool isSaving;
  final bool isDirty;
  final void Function(String role, bool checked) onToggle;
  final VoidCallback onSave;

  static const _roleLabels = {
    'ADMIN': 'Admin',
    'RH_MANAGER': 'RH Manager',
    'EMPLOYEE': 'Employé',
    'DIRECTION': 'Direction',
  };
  static const _roleColors = {
    'ADMIN': Color(0xFF6366F1),
    'RH_MANAGER': AppColors.primary,
    'EMPLOYEE': AppColors.accent,
    'DIRECTION': Color(0xFF10B981),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDirty
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.border,
          width: isDirty ? 1.2 : 0.6,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : code + description
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  permission.code,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (isDirty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Modifié',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            permission.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            permission.description,
            style: const TextStyle(fontSize: 12, color: AppColors.text2),
          ),
          const SizedBox(height: 14),

          // Checkboxes par rôle
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: const ['ADMIN', 'RH_MANAGER', 'EMPLOYEE', 'DIRECTION']
                .map((role) => _RoleCheckbox(
                      role: role,
                      label: _roleLabels[role] ?? role,
                      color: _roleColors[role] ?? AppColors.primary,
                      checked: pendingRoles.contains(role),
                      onChanged: (v) => onToggle(role, v ?? false),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),

          // Bouton Sauvegarder (visible uniquement si modifié)
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedOpacity(
              opacity: isDirty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: isDirty && !isSaving ? onSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 14),
                  label: Text(
                    isSaving ? 'Sauvegarde…' : 'Sauvegarder',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Checkbox stylisée par rôle ────────────────────────────────────────────

class _RoleCheckbox extends StatelessWidget {
  const _RoleCheckbox({
    required this.role,
    required this.label,
    required this.color,
    required this.checked,
    required this.onChanged,
  });

  final String role;
  final String label;
  final Color color;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: checked ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: checked ? color : AppColors.border,
            width: checked ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: checked,
                onChanged: onChanged,
                activeColor: color,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    checked ? FontWeight.w700 : FontWeight.w500,
                color: checked ? color : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
