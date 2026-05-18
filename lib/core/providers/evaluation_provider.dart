import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';

final evaluationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.get<Map<String, dynamic>>('/evaluations');
  final raw = resp.data?['items'] as List? ?? [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

final myEvaluationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.get<Map<String, dynamic>>('/evaluations/me');
  final raw = resp.data?['items'] as List? ?? [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

class EvaluationNotifier extends StateNotifier<bool> {
  EvaluationNotifier(this._api) : super(false);

  final ApiService _api;

  Future<bool> create(Map<String, dynamic> body) async {
    try {
      await _api.post<Map<String, dynamic>>('/evaluations', data: body);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> valider(int id) async {
    try {
      await _api.post<Map<String, dynamic>>('/evaluations/$id/valider');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> soumettre(int id) async {
    try {
      await _api.post<Map<String, dynamic>>('/evaluations/$id/soumettre');
      return true;
    } catch (_) {
      return false;
    }
  }
}

final evaluationNotifierProvider =
    StateNotifierProvider<EvaluationNotifier, bool>(
  (ref) => EvaluationNotifier(ref.read(apiServiceProvider)),
);
