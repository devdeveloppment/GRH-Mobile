import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/shared/models/departement.dart';

final departementsProvider =
    FutureProvider.autoDispose<List<Departement>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.get<Map<String, dynamic>>('/departements');
  final raw = resp.data?['items'] as List? ?? [];
  return raw.whereType<Map<String, dynamic>>().map(Departement.fromJson).toList();
});

final organigrammeProvider =
    FutureProvider.autoDispose<List<Departement>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.get<Map<String, dynamic>>('/departements/organigramme');
  final raw = resp.data?['tree'] as List? ?? [];
  return raw.whereType<Map<String, dynamic>>().map(Departement.fromJson).toList();
});

class DepartementNotifier extends StateNotifier<AsyncValue<List<Departement>>> {
  DepartementNotifier(this._api) : super(const AsyncLoading()) {
    load();
  }

  final ApiService _api;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final resp = await _api.get<Map<String, dynamic>>('/departements');
      final raw = resp.data?['items'] as List? ?? [];
      final items =
          raw.whereType<Map<String, dynamic>>().map(Departement.fromJson).toList();
      state = AsyncData(items);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<bool> create(Map<String, dynamic> body) async {
    try {
      await _api.post<Map<String, dynamic>>('/departements', data: body);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> body) async {
    try {
      await _api.put<Map<String, dynamic>>('/departements/$id', data: body);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> desactiver(int id) async {
    try {
      await _api.delete<void>('/departements/$id');
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final departementNotifierProvider =
    StateNotifierProvider<DepartementNotifier, AsyncValue<List<Departement>>>(
  (ref) => DepartementNotifier(ref.read(apiServiceProvider)),
);
