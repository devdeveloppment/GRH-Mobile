import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/notification_provider.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/notification_model.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final notif = ref.watch(notificationNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: AppRoutes.notifications,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: 'Notifications',
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
            actions: notif.unreadCount > 0
                ? [
                    TextButton(
                      onPressed: notif.isLoading
                          ? null
                          : () => ref
                              .read(notificationNotifierProvider)
                              .markAllAsRead(),
                      child: const Text(
                        'Tout marquer lu',
                        style: TextStyle(color: AppColors.primary, fontSize: 12),
                      ),
                    ),
                  ]
                : null,
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(
                currentRoute: AppRoutes.notifications, role: auth.role!),
          Expanded(
            child: _NotifBody(notif: notif),
          ),
        ],
      ),
    );
  }
}

class _NotifBody extends StatelessWidget {
  const _NotifBody({required this.notif});
  final NotificationNotifier notif;

  @override
  Widget build(BuildContext context) {
    if (notif.isLoading && notif.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notif.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 56, color: AppColors.text2.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text(
              'Aucune notification',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Future.value(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: notif.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final n = notif.notifications[index];
          return _NotifCard(notification: n, notif: notif);
        },
      ),
    );
  }
}

class _NotifCard extends ConsumerWidget {
  const _NotifCard({required this.notification, required this.notif});

  final AppNotification notification;
  final NotificationNotifier notif;

  static const _typeIcon = {
    'CONGE': Icons.event_available_outlined,
    'conge': Icons.event_available_outlined,
    'PAIE': Icons.payments_outlined,
    'paie': Icons.payments_outlined,
    'INFO': Icons.info_outline,
    'info': Icons.info_outline,
  };

  static const _typeColor = {
    'CONGE': AppColors.accent,
    'conge': AppColors.accent,
    'PAIE': AppColors.primary,
    'paie': AppColors.primary,
    'INFO': AppColors.text2,
    'info': AppColors.text2,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.read;
    final icon = _typeIcon[notification.type] ?? Icons.notifications_outlined;
    final color = _typeColor[notification.type] ?? AppColors.primary;

    return GestureDetector(
      onTap: isUnread
          ? () => ref
              .read(notificationNotifierProvider)
              .markAsRead(notification.id)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.primary.withOpacity(0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône type
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.titre ?? notification.type,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.text1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppFormatters.relativeTime(notification.date),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.text2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.text2, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
