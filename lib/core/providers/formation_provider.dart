import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';

final formationsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String?>(
  (ref, statut) async {
    final api = ref.read(apiServiceProvider);
    final query = statut != null ? '?statut=$statut' : '';
    final resp = await api.get<Map<String, dynamic>>('/formations$query');
    final raw = resp.data?['items'] as List? ?? [];
    return raw.whereType<Map<String, dynamic>>().toList();
  },
);

class FormationNotifier extends StateNotifier<bool> {
  FormationNotifier(this._api) : super(false);

  final ApiService _api;

  Future<bool> create(Map<String, dynamic> body) async {
    try {
      await _api.post<Map<String, dynamic>>('/formations', data: body);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> inscrire(int formationId, String matricule) async {
    try {
      await _api.post<void>('/formations/$formationId/inscrire/$matricule');
      return true;
    } catch (_) {
      return false;
    }
  }
}

final formationNotifierProvider =
    StateNotifierProvider<FormationNotifier, bool>(
  (ref) => FormationNotifier(ref.read(apiServiceProvider)),
);
