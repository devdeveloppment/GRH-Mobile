import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/dashboard_summary.dart';
import 'package:grh_mobile/shared/models/dashboard_models.dart';

final dashboardNotifierProvider =
    ChangeNotifierProvider.autoDispose<DashboardNotifier>((ref) {
  final notifier = DashboardNotifier(ref);
  unawaited(notifier.load());
  return notifier;
});

final enhancedDashboardProvider = 
    FutureProvider.autoDispose<EnhancedDashboard>((ref) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.get<Map<String, dynamic>>('/dashboard/enhanced');
  return EnhancedDashboard.fromJson(response.data ?? <String, dynamic>{});
});

class DashboardNotifier extends ChangeNotifier {
  DashboardNotifier(this._ref);

  final Ref _ref;
  DashboardSummary? summary;
  bool isLoading = false;
  String? error;
  Timer? _refreshTimer;

  Future<void> load() async {
    isLoading = true;
    error = null;
    final cache = _ref.read(cacheServiceProvider);
    final cachedSummary = await cache.readMap('dashboard_summary');
    if (cachedSummary != null && summary == null) {
      summary = DashboardSummary.fromJson(cachedSummary);
      notifyListeners();
    }
    notifyListeners();

    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.get<Map<String, dynamic>>('/dashboard/summary');
      summary = DashboardSummary.fromJson(response.data ?? <String, dynamic>{});
      await cache.writeMap('dashboard_summary', summary!.toJson());
      _refreshTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
        unawaited(refreshSilently());
      });
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSilently() async {
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.get<Map<String, dynamic>>('/dashboard/summary');
      summary = DashboardSummary.fromJson(response.data ?? <String, dynamic>{});
      await _ref.read(cacheServiceProvider).writeMap('dashboard_summary', summary!.toJson());
      notifyListeners();
    } catch (_) {
      // Silence volontaire pour ne pas interrompre l'utilisateur.
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
