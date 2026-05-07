import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/grh_logo.dart';

class GrhSidebar extends ConsumerWidget {
  const GrhSidebar({
    super.key,
    required this.currentRoute,
    required this.role,
    this.isDrawer = false,
  });

  final String currentRoute;
  final UserRole role;
  final bool isDrawer;

  // Largeur fixe définie par la charte : 210px
  static const double kWidth = 210;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth  = ref.watch(authNotifierProvider);
    final items = navigationItemsForRole(role);

    return Container(
      width: isDrawer ? kWidth + 20 : kWidth,
      color: AppColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
              child: GrhLogo(iconSize: 32, textScale: 0.75, darkBackground: true),
            ),

            // ── Séparateur ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                height: 0.5,
                color: Colors.white.withOpacity(0.12),
              ),
            ),

            // ── Items de navigation ───────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final bool isActive =
                      currentRoute == item.route ||
                      (currentRoute.startsWith(AppRoutes.employees) &&
                          item.route == AppRoutes.employees);

                  return _NavItem(
                    item:     item,
                    isActive: isActive,
                    onTap: () {
                      context.go(item.route);
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),

            // ── Séparateur ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 0.5,
                color: Colors.white.withOpacity(0.12),
              ),
            ),

            // ── User info ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(AppRoutes.profile),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accent,
                          backgroundImage: auth.user?.photoUrl != null 
                            ? NetworkImage(auth.user!.photoUrl!)
                            : null,
                          child: auth.user?.photoUrl == null
                            ? Text(
                              _initials(auth.user?.fullName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            )
                            : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                auth.user?.fullName ?? 'Utilisateur',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                role.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.sidebarItem,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Déconnexion',
                          onPressed: () => ref.read(authNotifierProvider).logout(),
                          icon: const Icon(Icons.logout_rounded,
                              color: AppColors.sidebarItem, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();
  }
}

// ── Item de navigation individuel ──────────────────────────────────────────
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavigationItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Actif : fond #F68A1E, radius 0 8px 8px 0, margin-right 8px
    // Repos : transparent, icône+label #9FE1CB
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        margin: EdgeInsets.only(right: isActive ? 8 : 0),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topRight:    Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.only(
            topRight:    Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isActive ? Colors.white : AppColors.sidebarItem,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? Colors.white : AppColors.sidebarItem,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
