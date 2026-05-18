import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/notification_model.dart';

// Provider sans autoDispose pour conserver l'état et le timer actifs
final notificationNotifierProvider =
    ChangeNotifierProvider<NotificationNotifier>((ref) {
  final notifier = NotificationNotifier(ref);
  unawaited(notifier.load());
  notifier._startPolling();
  return notifier;
});

class NotificationNotifier extends ChangeNotifier {
  NotificationNotifier(this._ref);

  final Ref _ref;
  List<AppNotification> notifications = [];
  bool isLoading = false;
  String? error;
  Timer? _timer;

  int get unreadCount => notifications.where((n) => !n.read).length;

  // ── Polling automatique toutes les 60 secondes ─────────────────────────────
  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => load(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Chargement ─────────────────────────────────────────────────────────────
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }
    try {
      final api = _ref.read(apiServiceProvider);
      final response =
          await api.get<Map<String, dynamic>>('/notifications');
      final raw = response.data?['items'] as List<dynamic>?
          ?? response.data?['data']  as List<dynamic>?
          ?? [];
      notifications = raw
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
    } catch (e) {
      if (!silent) error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Marquer une notif lue ──────────────────────────────────────────────────
  Future<void> markAsRead(int id) async {
    // Mise à jour optimiste immédiate
    final prev = List<AppNotification>.from(notifications);
    notifications = notifications.map((n) {
      return n.id == id ? n.copyWith(read: true, readAt: DateTime.now()) : n;
    }).toList();
    notifyListeners();

    try {
      final api = _ref.read(apiServiceProvider);
      await api.put<dynamic>('/notifications/$id/read');
    } catch (_) {
      // Rollback si erreur réseau
      notifications = prev;
      notifyListeners();
    }
  }

  // ── Tout marquer lu ────────────────────────────────────────────────────────
  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    final prev = List<AppNotification>.from(notifications);
    notifications = notifications
        .map((n) => n.copyWith(read: true, readAt: now))
        .toList();
    notifyListeners();

    try {
      final api = _ref.read(apiServiceProvider);
      await api.put<dynamic>('/notifications/read-all');
    } catch (_) {
      notifications = prev;
      notifyListeners();
    }
  }
}
