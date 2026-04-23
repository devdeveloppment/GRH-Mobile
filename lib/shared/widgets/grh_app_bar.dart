import 'package:flutter/material.dart';
import 'package:grh_mobile/shared/widgets/grh_logo.dart';

class GrhAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 72,
      leading: showBack
          ? IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            )
          : onMenuTap != null
              ? IconButton(
                  onPressed: onMenuTap,
                  icon: const Icon(Icons.menu_rounded),
                )
              : null,
      titleSpacing: 8,
      title: Row(
        children: [
          const GrhLogo(iconSize: 36, textScale: 0.78),
          const SizedBox(width: 14),
          if (MediaQuery.sizeOf(context).width > 720)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (userName != null)
                  Text(
                    userName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
              ],
            )
          else
            Text(title),
        ],
      ),
      actions: actions,
    );
  }
}
