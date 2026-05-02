import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/notification_model.dart';

final notificationNotifierProvider =
    ChangeNotifierProvider.autoDispose<NotificationNotifier>((ref) {
  final notifier = NotificationNotifier(ref);
  unawaited(notifier.load());
  return notifier;
});

class NotificationNotifier extends ChangeNotifier {
  NotificationNotifier(this._ref);

  final Ref _ref;
  List<AppNotification> notifications = [];
  bool isLoading = false;
  String? error;

  int get unreadCount => notifications.where((n) => !n.read).length;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final api = _ref.read(apiServiceProvider);
      final response =
          await api.get<Map<String, dynamic>>('/notifications');
      final raw =
          response.data?['items'] as List<dynamic>? ??
          response.data?['data']  as List<dynamic>? ??
          [];
      notifications = raw
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _ref
          .read(apiServiceProvider)
          .put<void>('/notifications/$id/read');
      notifications = notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _ref
          .read(apiServiceProvider)
          .put<void>('/notifications/read-all');
      notifications = notifications.map((n) => n.copyWith(read: true)).toList();
      notifyListeners();
    } catch (_) {}
  }
}
