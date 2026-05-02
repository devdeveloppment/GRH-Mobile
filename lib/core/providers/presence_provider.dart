import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/presence.dart';

final presenceNotifierProvider =
    ChangeNotifierProvider.autoDispose<PresenceNotifier>((ref) {
  final notifier = PresenceNotifier(ref);
  unawaited(notifier.load());
  return notifier;
});

class PresenceNotifier extends ChangeNotifier {
  PresenceNotifier(this._ref);

  final Ref _ref;
  List<Presence> presences = [];
  bool isLoading = false;
  String? error;
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic> monthlyStats = {};

  // ── Computed stats ──────────────────────────────────────────────────────────
  int get presentCount =>
      presences.where((p) => p.statut == 'PRESENT').length;
  int get absentCount =>
      presences.where((p) => p.statut == 'ABSENT').length;
  int get retardCount =>
      presences.where((p) => p.statut == 'RETARD').length;

  double get tauxPresence {
    final total = presentCount + absentCount + retardCount;
    if (total == 0) return 100.0;
    return (presentCount + retardCount) / total * 100;
  }

  Set<String> get presentDays => {
        for (final p in presences.where((p) => p.statut == 'PRESENT'))
          _key(p.date),
      };

  Set<String> get absentDays => {
        for (final p in presences.where((p) => p.statut == 'ABSENT'))
          _key(p.date),
      };

  Set<String> get retardDays => {
        for (final p in presences.where((p) => p.statut == 'RETARD'))
          _key(p.date),
      };

  static String _key(DateTime d) => d.toIso8601String().substring(0, 10);

  // ── Load ────────────────────────────────────────────────────────────────────
  Future<void> load({DateTime? month}) async {
    if (month != null) {
      currentMonth = DateTime(month.year, month.month);
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.get<Map<String, dynamic>>(
        '/presences/me',
        queryParameters: {
          'month': currentMonth.month,
          'year': currentMonth.year,
        },
      );
      final raw =
          response.data?['items'] as List<dynamic>? ??
          response.data?['data']  as List<dynamic>? ??
          [];
      presences = raw
          .whereType<Map<String, dynamic>>()
          .map(Presence.fromJson)
          .toList();
      
      // Charger les stats mensuelles
      monthlyStats = response.data?['stats'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeMonth(DateTime month) => load(month: month);

  // ── Pointage (clock-in / clock-out) ────────────────────────────────────────
  Future<void> pointer() async {
    try {
      await _ref.read(apiServiceProvider).post<void>('/presences/pointage');
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  // ── Signaler absence ────────────────────────────────────────────────────────
  Future<void> reportAbsence({
    required DateTime date,
    required String reason,
  }) async {
    try {
      await _ref.read(apiServiceProvider).post<void>(
        '/presences/report-absence',
        data: {
          'date': date.toIso8601String(),
          'reason': reason,
        },
      );
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  // ── Justifier absence ──────────────────────────────────────────────────────
  Future<void> justifyAbsence({
    required int presenceId,
    required String justification,
  }) async {
    try {
      await _ref.read(apiServiceProvider).post<void>(
        '/presences/$presenceId/justify',
        data: {'justification': justification},
      );
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
