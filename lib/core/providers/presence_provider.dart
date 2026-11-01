import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/services/api_service.dart';
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
  List<Presence> absencesEnAttente = [];
  bool isLoading = false;
  bool isPointerLoading = false;
  bool isAbsenceLoading = false;
  String? error;
  String? pointerError;
  String? absenceError;
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

  // ── Pointage Entrée ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> pointageEntree({
    required double latitude,
    required double longitude,
  }) async {
    return _pointage('ENTREE', latitude, longitude);
  }

  // ── Pointage Sortie ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> pointageSortie({
    required double latitude,
    required double longitude,
  }) async {
    return _pointage('SORTIE', latitude, longitude);
  }

  // ── Internal pointage handler ──────────────────────────────────────────────
  Future<Map<String, dynamic>?> _pointage(
    String type,
    double latitude,
    double longitude,
  ) async {
    try {
      isPointerLoading = true;
      pointerError = null;
      notifyListeners();

      final api = _ref.read(apiServiceProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/presences/pointage',
        data: {
          'type': type,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      await load();
      return response.data;
    } catch (e) {
      pointerError = ApiService.messageOf(e, 'Pointage impossible.');
      notifyListeners();
      return null;
    } finally {
      isPointerLoading = false;
      notifyListeners();
    }
  }

  // ── Signaler absence ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> reportAbsence({
    required DateTime date,
    required String motif,
  }) async {
    try {
      isAbsenceLoading = true;
      absenceError = null;
      notifyListeners();

      final api = _ref.read(apiServiceProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/presences/report-absence',
        data: {
          'date': date.toIso8601String().split('T')[0],
          'motif': motif,
        },
      );

      await load();
      await loadAbsencesEnAttente();
      return response.data;
    } catch (e) {
      absenceError = ApiService.messageOf(e, 'Opération impossible.');
      notifyListeners();
      return null;
    } finally {
      isAbsenceLoading = false;
      notifyListeners();
    }
  }

  // ── Charger les absences en attente ────────────────────────────────────────
  Future<void> loadAbsencesEnAttente() async {
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.get<Map<String, dynamic>>(
        '/presences/absences-en-attente',
      );
      final raw = response.data?['items'] as List<dynamic>? ?? [];
      absencesEnAttente = raw
          .whereType<Map<String, dynamic>>()
          .map(Presence.fromJson)
          .toList();
      notifyListeners();
    } catch (e) {
      absenceError = ApiService.messageOf(e, 'Opération impossible.');
      notifyListeners();
    }
  }

  // ── Justifier absence ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> justifyAbsence({
    required int presenceId,
    required String justification,
    String? pieceJointe,
  }) async {
    try {
      isAbsenceLoading = true;
      absenceError = null;
      notifyListeners();

      final api = _ref.read(apiServiceProvider);
      final response = await api.put<Map<String, dynamic>>(
        '/presences/$presenceId/justify',
        data: {
          'justification': justification,
          if (pieceJointe != null) 'pieceJointe': pieceJointe,
        },
      );

      await load();
      await loadAbsencesEnAttente();
      return response.data;
    } catch (e) {
      absenceError = ApiService.messageOf(e, 'Opération impossible.');
      notifyListeners();
      return null;
    } finally {
      isAbsenceLoading = false;
      notifyListeners();
    }
  }
}
