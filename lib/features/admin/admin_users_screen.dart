import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/providers/admin_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

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
    Future.microtask(
      () => ref.read(adminNotifierProvider).loadUsers(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminNotifierProvider);
    final filteredUsers = admin.users
        .where(
          (u) =>
              u.email.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              (u.fullName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GrhAppBar(title: 'Gestion des Utilisateurs'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par email ou nom...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (admin.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (filteredUsers.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Aucun utilisateur trouvé',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (ctx, idx) {
                  final user = filteredUsers[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(user.fullName ?? user.email),
                      subtitle: Text(user.email),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          StatusBadge(
                            label: user.role.toString().split('.').last,
                            type: _getRoleType(user.role),
                          ),
                          PopupMenuButton(
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                child: const Text('Éditer'),
                                onTap: () =>
                                    _showEditUserDialog(context, user),
                              ),
                              PopupMenuItem(
                                child: const Text('Réinitialiser mot de passe'),
                                onTap: () =>
                                    _showResetPasswordDialog(context, user),
                              ),
                              PopupMenuItem(
                                child: const Text('Supprimer'),
                                onTap: () =>
                                    _showDeleteConfirmation(context, user.id ?? 0),
                              ),
                            ],
                          ),
                        ],
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

  void _showCreateUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String email = '';
    String fullName = '';
    String role = 'EMPLOYEE';
    String password = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Créer un nouvel utilisateur'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  onChanged: (v) => fullName = v,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  onChanged: (v) => email = v,
                ),
                DropdownButtonFormField(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Rôle'),
                  items: const ['ADMIN', 'RH_MANAGER', 'EMPLOYEE', 'DIRECTION']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => role = v ?? 'EMPLOYEE',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator: (v) =>
                      (v?.length ?? 0) < 6 ? 'Min 6 caractères' : null,
                  onChanged: (v) => password = v,
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
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(adminNotifierProvider).createUser(
                      email: email,
                      fullName: fullName,
                      role: role,
                      password: password,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, dynamic user) {
    final formKey = GlobalKey<FormState>();
    String email = user.email;
    String fullName = user.fullName ?? '';
    String role = user.role.toString().split('.').last;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Éditer l\'utilisateur'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: fullName,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  onChanged: (v) => fullName = v,
                ),
                TextFormField(
                  initialValue: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (v) => email = v,
                ),
                DropdownButtonFormField(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Rôle'),
                  items: const ['ADMIN', 'RH_MANAGER', 'EMPLOYEE', 'DIRECTION']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => role = v ?? 'EMPLOYEE',
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
          TextButton(
            onPressed: () {
              ref.read(adminNotifierProvider).updateUser(
                    userId: user.id ?? 0,
                    email: email,
                    fullName: fullName,
                    role: role,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, dynamic user) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: 'Nouveau mot de passe',
            hintText: 'Min 6 caractères',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (passwordController.text.length >= 6) {
                ref.read(adminNotifierProvider).resetUserPassword(
                      user.id ?? 0,
                      passwordController.text,
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe réinitialisé')),
                );
              }
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminNotifierProvider).deleteUser(userId);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getRoleType(dynamic role) {
    final roleStr = role.toString().split('.').last;
    return {
      'ADMIN': 'error',
      'RH_MANAGER': 'warning',
      'DIRECTION': 'info',
      'EMPLOYEE': 'success',
    }[roleStr] ??
        'info';
  }
}
