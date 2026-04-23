import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/african_pattern.dart';
import 'package:grh_mobile/shared/widgets/grh_logo.dart';

class GrhSidebar extends StatefulWidget {
  const GrhSidebar({
    super.key,
    required this.currentRoute,
    required this.role,
    this.isDrawer = false,
  });

  final String currentRoute;
  final UserRole role;
  final bool isDrawer;

  @override
  State<GrhSidebar> createState() => _GrhSidebarState();
}

class _GrhSidebarState extends State<GrhSidebar> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final items = navigationItemsForRole(widget.role);
    final width = widget.isDrawer ? 290.0 : (_collapsed ? 96.0 : 278.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: AfricanPattern(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Row(
                  children: [
                    if (!_collapsed || widget.isDrawer) const Expanded(child: GrhLogo(iconSize: 34, textScale: 0.72)),
                    if (!widget.isDrawer)
                      IconButton(
                        tooltip: _collapsed ? 'Déplier' : 'Réduire',
                        onPressed: () => setState(() => _collapsed = !_collapsed),
                        icon: Icon(_collapsed ? Icons.menu_open_rounded : Icons.menu_rounded),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final bool isActive = widget.currentRoute == item.route ||
                        (widget.currentRoute.startsWith(AppRoutes.employees) &&
                            item.route == AppRoutes.employees);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.accent.withOpacity(0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        minLeadingWidth: 24,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        leading: Icon(
                          item.icon,
                          color: isActive ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        title: _collapsed && !widget.isDrawer
                            ? null
                            : Text(
                                item.label,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                      color: isActive ? AppColors.primary : null,
                                    ),
                              ),
                        onTap: () {
                          context.go(item.route);
                          if (widget.isDrawer) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: items.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
