import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_logo.dart';

class GrhAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const GrhAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
    this.userName,
    this.onMenuTap,
  });

  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final String? userName;
  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth   = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width > 920;

    final logoutBtn = isWide
        ? Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: auth.isAuthenticated
                  ? () => ref.read(authNotifierProvider).logout()
                  : null,
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Déconnexion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                backgroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          )
        : IconButton(
            tooltip: 'Déconnexion',
            onPressed: auth.isAuthenticated
                ? () => ref.read(authNotifierProvider).logout()
                : null,
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.text2,
          );

    return AppBar(
      leadingWidth: (showBack || onMenuTap != null) ? 64 : 0,
      toolbarHeight: preferredSize.height,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.border),
      ),
      leading: (showBack || onMenuTap != null)
          ? Padding(
              padding: const EdgeInsets.only(left: 16, top: 14, bottom: 14),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: showBack
                      ? () => Navigator.of(context).maybePop()
                      : onMenuTap,
                  child: Icon(
                    showBack
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.menu_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            )
          : null,
      titleSpacing: 12,
      title: Row(
        children: [
          if (!isWide) ...[
            const GrhLogo(iconSize: 28, textScale: 0.65),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1,
                  ),
                ),
                if (userName != null)
                  Text(
                    userName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [...?actions, logoutBtn],
    );
  }
}
