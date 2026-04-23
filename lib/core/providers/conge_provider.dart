import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/conge.dart';

final congeNotifierProvider =
    ChangeNotifierProvider.autoDispose<CongeNotifier>((ref) {
  final notifier = CongeNotifier(ref);
  unawaited(notifier.load());
  return notifier;
});

class CongeNotifier extends ChangeNotifier {
  CongeNotifier(this._ref);

  final Ref _ref;
  List<Conge> demandes = <Conge>[];
  bool isLoading = false;
  double soldeRestant = 0;

  Future<void> load() async {
    isLoading = true;
    final cached = await _ref.read(cacheServiceProvider).readMap('conges');
    if (cached != null && demandes.isEmpty) {
      final cachedItems = cached['items'] as List<dynamic>? ?? <dynamic>[];
      demandes = cachedItems
          .whereType<Map<String, dynamic>>()
          .map(Conge.fromJson)
          .toList(growable: false);
      soldeRestant = (cached['soldeRestant'] as num?)?.toDouble() ?? soldeRestant;
    }
    notifyListeners();
    try {
      final api = _ref.read(apiServiceProvider);
      final auth = _ref.read(authNotifierProvider);
      final role = auth.role;
      final endpoint = role == null || role.name == 'employee'
          ? '/conges/me'
          : '/conges';
      final response = await api.get<Map<String, dynamic>>(endpoint);
      final payload = response.data ?? <String, dynamic>{};
      final rawItems = payload['items'] as List<dynamic>? ??
          payload['data'] as List<dynamic>? ??
          <dynamic>[];
      demandes = rawItems
          .whereType<Map<String, dynamic>>()
          .map(Conge.fromJson)
          .toList(growable: false);
      soldeRestant = (payload['soldeRestant'] as num?)?.toDouble() ?? soldeRestant;
      await _ref.read(cacheServiceProvider).writeMap(
            'conges',
            {
              'soldeRestant': soldeRestant,
              'items': demandes.map((item) => item.toJson()).toList(growable: false),
            },
          );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitRequest({
    required String typeConge,
    required DateTime dateDebut,
    required DateTime dateFin,
    String? motif,
  }) async {
    final api = _ref.read(apiServiceProvider);
    final int nombreJours = dateFin.difference(dateDebut).inDays + 1;
    await api.post<Map<String, dynamic>>(
      '/conges',
      data: {
        'typeConge': typeConge,
        'dateDebut': dateDebut.toIso8601String(),
        'dateFin': dateFin.toIso8601String(),
        'nombreJours': nombreJours,
        'motif': motif,
      },
    );
    await load();
  }

  Future<void> approve(int congeId) async {
    final api = _ref.read(apiServiceProvider);
    await api.post<void>('/conges/$congeId/approve');
    await load();
  }

  Future<void> reject(int congeId, {String? commentaire}) async {
    final api = _ref.read(apiServiceProvider);
    await api.post<void>(
      '/conges/$congeId/reject',
      data: {'commentaire': commentaire},
    );
    await load();
  }
}
