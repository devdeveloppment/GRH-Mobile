import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/shared/models/poste.dart';

class PosteNotifier extends StateNotifier<AsyncValue<List<Poste>>> {
  PosteNotifier(this._api) : super(const AsyncLoading()) {
    load();
  }

  final ApiService _api;

  Future<void> load({int? departementId}) async {
    state = const AsyncLoading();
    try {
      final query = departementId != null ? '?departementId=$departementId' : '';
      final resp = await _api.get<Map<String, dynamic>>('/postes$query');
      final raw = resp.data?['items'] as List? ?? [];
      state = AsyncData(
          raw.whereType<Map<String, dynamic>>().map(Poste.fromJson).toList());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<bool> create(Map<String, dynamic> body) async {
    try {
      await _api.post<Map<String, dynamic>>('/postes', data: body);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> body) async {
    try {
      await _api.put<Map<String, dynamic>>('/postes/$id', data: body);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final posteNotifierProvider =
    StateNotifierProvider<PosteNotifier, AsyncValue<List<Poste>>>(
  (ref) => PosteNotifier(ref.read(apiServiceProvider)),
);
