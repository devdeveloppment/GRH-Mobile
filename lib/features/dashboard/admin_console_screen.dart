import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/kpi_card.dart';
import 'package:grh_mobile/shared/widgets/section_header.dart';

class AdminConsoleScreen extends ConsumerStatefulWidget {
  const AdminConsoleScreen({
    super.key,
    required this.sectionTitle,
  });

  final String sectionTitle;

  @override
  ConsumerState<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends ConsumerState<AdminConsoleScreen> {
  bool ssoEnabled = true;
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final currentRoute = switch (widget.sectionTitle) {
      'Utilisateurs' => AppRoutes.adminUsers,
      'Rôles' => AppRoutes.adminRoles,
      'Paramètres' => AppRoutes.adminSettings,
      _ => AppRoutes.adminDashboard,
    };

    return Scaffold(
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: currentRoute,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: Builder(
        builder: (scaffoldContext) => GrhAppBar(
          title: 'Administration',
          userName: auth.user?.fullName,
          onMenuTap: isWide ? null : () => Scaffold.of(scaffoldContext).openDrawer(),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: currentRoute, role: auth.role!),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sectionTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: const [
                      SizedBox(
                        width: 260,
                        child: KpiCard(
                          title: 'Utilisateurs actifs',
                          value: '84',
                          icon: Icons.group_outlined,
                          color: Color(0xFF0F4D3F),
                          trend: 6.1,
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: KpiCard(
                          title: 'Rôles configurés',
                          value: '12',
                          icon: Icons.verified_user_outlined,
                          color: Color(0xFFF26422),
                          trend: 1.4,
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: KpiCard(
                          title: 'Connexions SSO',
                          value: '99.98%',
                          icon: Icons.lock_person_outlined,
                          color: Color(0xFF2D7FF9),
                          trend: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Gouvernance & sécurité'),
                          const SizedBox(height: 10),
                          SwitchListTile.adaptive(
                            value: ssoEnabled,
                            onChanged: (value) => setState(() => ssoEnabled = value),
                            title: const Text('Authentification SSO / Azure AD'),
                            subtitle: const Text('Renforce le contrôle d’accès pour les comptes d’entreprise.'),
                          ),
                          SwitchListTile.adaptive(
                            value: notificationsEnabled,
                            onChanged: (value) => setState(() => notificationsEnabled = value),
                            title: const Text('Notifications administrateur'),
                            subtitle: const Text('Alertes sur les incidents, exports et erreurs critiques.'),
                          ),
                          const Divider(height: 28),
                          ListTile(
                            leading: const Icon(Icons.cloud_outlined),
                            title: const Text('Hébergement AWS'),
                            subtitle: const Text('Déploiement cible: ECS Fargate, RDS PostgreSQL, CloudFront, WAF.'),
                            trailing: FilledButton.tonal(
                              onPressed: () {},
                              child: const Text('Vérifier'),
                            ),
                          ),
                        ],
                      ),
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
}
