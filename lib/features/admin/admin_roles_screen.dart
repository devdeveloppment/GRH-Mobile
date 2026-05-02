import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/providers/admin_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';

class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminNotifierProvider);
    
    final rolesPermissions = {
      'ADMIN': [
        'Accès total au système',
        'Gestion des utilisateurs',
        'Configuration système',
        'Gestion des rôles',
        'Voir tous les rapports',
      ],
      'RH_MANAGER': [
        'Gestion des employés',
        'Gestion des congés',
        'Gestion des présences',
        'Gestion de la paie',
        'Rapports RH',
      ],
      'EMPLOYEE': [
        'Consulter son profil',
        'Voir ses congés',
        'Voir ses présences',
        'Consulter sa paie',
        'Soumettre demande de congé',
      ],
      'DIRECTION': [
        'Consulter tous les rapports',
        'Vue d\'ensemble dashboard',
        'Statistiques annuelles',
        'Présences globales',
      ],
    };

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GrhAppBar(title: 'Rôles & Permissions'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: admin.roles.length,
        itemBuilder: (ctx, idx) {
          final role = admin.roles[idx];
          final permissions = rolesPermissions[role] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                role,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('${permissions.length} permissions'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: permissions
                        .map(
                          (perm) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(perm)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
