import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/admin_provider.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/grh_surface_card.dart';

class AdminUsersManagementScreen extends ConsumerStatefulWidget {
  const AdminUsersManagementScreen({super.key});

  @override
  ConsumerState<AdminUsersManagementScreen> createState() =>
      _AdminUsersManagementScreenState();
}

class _AdminUsersManagementScreenState
    extends ConsumerState<AdminUsersManagementScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(() => ref.read(adminNotifierProvider).loadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final admin = ref.watch(adminNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    final q = _searchController.text.toLowerCase();
    final filteredUsers = admin.users.where((u) {
      if (q.isEmpty) return true;
      return u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    // Afficher l'erreur via SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (admin.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            backgroundColor: AppColors.error,
            content: Text(admin.errorMessage!),
          ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.adminUsers,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Gestion des Utilisateurs',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: () => _showCreateUserDialog(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Ajouter'),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: AppRoutes.adminUsers, role: auth.role!),
          Expanded(
            child: Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un utilisateur...',
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: AppColors.text2),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${filteredUsers.length} utilisateur${filteredUsers.length > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ),

                if (admin.isLoading && admin.users.isEmpty)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else if (filteredUsers.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off_outlined,
                              size: 56, color: AppColors.textSecondaryLight),
                          const SizedBox(height: 12),
                          Text('Aucun utilisateur trouvé',
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.read(adminNotifierProvider).loadUsers(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filteredUsers.length,
                        itemBuilder: (ctx, idx) =>
                            _UserCard(
                          user: filteredUsers[idx],
                          onEdit: () => _showEditUserDialog(
                              context, filteredUsers[idx]),
                          onDelete: () => _showDeleteConfirmation(
                              context, filteredUsers[idx].id),
                          onToggle: () => ref
                              .read(adminNotifierProvider)
                              .toggleUser(filteredUsers[idx].id),
                        ),
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

  void _showCreateUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'EMPLOYEE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nouvel utilisateur'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Adresse email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => (v ?? '').contains('@')
                        ? null
                        : 'Email invalide',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Rôle',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                      DropdownMenuItem(
                          value: 'RH_MANAGER', child: Text('Responsable RH')),
                      DropdownMenuItem(
                          value: 'DIRECTION', child: Text('Direction')),
                      DropdownMenuItem(
                          value: 'EMPLOYEE', child: Text('Employé')),
                    ],
                    onChanged: (v) => setS(() => role = v ?? 'EMPLOYEE'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe provisoire',
                      prefixIcon: Icon(Icons.lock_outline),
                      hintText: 'Laissez vide pour ChangeMe@123',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final ok =
                    await ref.read(adminNotifierProvider).createUser(
                          email: emailCtrl.text.trim(),
                          fullName: nameCtrl.text.trim(),
                          role: role,
                          password: passCtrl.text.trim().isEmpty
                              ? 'ChangeMe@123'
                              : passCtrl.text.trim(),
                        );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor:
                        ok ? AppColors.success : AppColors.error,
                    content: Text(ok
                        ? 'Utilisateur créé avec succès.'
                        : ref.read(adminNotifierProvider).errorMessage ??
                            'Erreur lors de la création.'),
                  ));
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, Utilisateur user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl =
        TextEditingController(text: user.fullName);
    final emailCtrl = TextEditingController(text: user.email);
    String role = user.role.apiValue;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Modifier l\'utilisateur'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nom complet'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Adresse email'),
                    validator: (v) => (v ?? '').contains('@')
                        ? null
                        : 'Email invalide',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Rôle'),
                    items: const [
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                      DropdownMenuItem(
                          value: 'RH_MANAGER', child: Text('Responsable RH')),
                      DropdownMenuItem(
                          value: 'DIRECTION', child: Text('Direction')),
                      DropdownMenuItem(
                          value: 'EMPLOYEE', child: Text('Employé')),
                    ],
                    onChanged: (v) => setS(() => role = v ?? 'EMPLOYEE'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await ref.read(adminNotifierProvider).updateUser(
                      userId: user.id,
                      email: emailCtrl.text.trim(),
                      fullName: nameCtrl.text.trim(),
                      role: role,
                    );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver l\'utilisateur ?'),
        content: const Text(
            'L\'utilisateur sera désactivé et ne pourra plus se connecter.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminNotifierProvider).deleteUser(userId);
            },
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }
}

// ── Carte utilisateur ──────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final Utilisateur user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roleLabel(user.role);
    final roleColor = _roleColor(user.role);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GrhSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
        children: [
          EmployeeAvatar(name: user.fullName, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondaryLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: user.actif ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      user.actif ? 'Actif' : 'Inactif',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: user.actif
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondaryLight),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'toggle') onToggle();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ]),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(
                      user.actif
                          ? Icons.block_rounded
                          : Icons.check_circle_outline,
                      size: 18),
                  const SizedBox(width: 8),
                  Text(user.actif ? 'Désactiver' : 'Réactiver'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Supprimer',
                      style: TextStyle(color: AppColors.error)),
                ]),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.rhManager:
        return 'Resp. RH';
      case UserRole.direction:
        return 'Direction';
      default:
        return 'Employé';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return AppColors.error;
      case UserRole.admin:
        return AppColors.error;
      case UserRole.rhManager:
        return AppColors.warning;
      case UserRole.direction:
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }
}
