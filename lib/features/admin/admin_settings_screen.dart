import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/admin_provider.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  late Map<String, bool> tempSettings;

  @override
  void initState() {
    super.initState();
    final admin = ref.read(adminNotifierProvider);
    tempSettings = Map.from(admin.settings);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final admin = ref.watch(adminNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.adminSettings,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Paramètres Système',
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
                currentRoute: AppRoutes.adminSettings, role: auth.role!),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
          const Text(
            'Configuration système',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _SettingToggleTile(
            title: 'Authentification SSO',
            subtitle: 'Active l\'authentification unique',
            value: tempSettings['SSO'] ?? false,
            onChanged: (v) => setState(() => tempSettings['SSO'] = v),
          ),
          _SettingToggleTile(
            title: 'Notifications par email',
            subtitle: 'Envoyer les notifications par email',
            value: tempSettings['NOTIFICATIONS'] ?? false,
            onChanged: (v) => setState(() => tempSettings['NOTIFICATIONS'] = v),
          ),
          _SettingToggleTile(
            title: 'Déconnexion automatique',
            subtitle: 'Déconnecter après inactivité (30 min)',
            value: tempSettings['AUTO_LOGOUT'] ?? false,
            onChanged: (v) => setState(() => tempSettings['AUTO_LOGOUT'] = v),
          ),
          _SettingToggleTile(
            title: 'Authentification 2FA',
            subtitle: 'Activer la vérification à deux facteurs',
            value: tempSettings['TWO_FACTOR'] ?? false,
            onChanged: (v) => setState(() => tempSettings['TWO_FACTOR'] = v),
          ),
          const SizedBox(height: 32),
          const Text(
            'Informations système',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: admin.getSystemStats(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final stats = snapshot.data ?? {};
              return Column(
                children: [
                  _StatCard(
                    title: 'Utilisateurs actifs',
                    value: '${stats['activeUsers'] ?? 0}',
                  ),
                  _StatCard(
                    title: 'Employés',
                    value: '${stats['totalEmployees'] ?? 0}',
                  ),
                  _StatCard(
                    title: 'Demandes de congés en attente',
                    value: '${stats['pendingLeaves'] ?? 0}',
                  ),
                  _StatCard(
                    title: 'Taux de présence du jour',
                    value: '${stats['attendanceRate'] ?? 0}%',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: admin.isLoading
                  ? null
                  : () {
                      ref.read(adminNotifierProvider).updateSettings(tempSettings);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Paramètres mis à jour'),
                        ),
                      );
                    },
              child: admin.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Enregistrer'),
            ),
          ),
          if (admin.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  admin.errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
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
}

class _SettingToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _SettingToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
