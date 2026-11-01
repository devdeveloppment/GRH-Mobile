import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/core/constants/app_globals.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
      // Seuls les profils qui valident des congés consultent la liste globale (filtrée côté serveur)
      const validators = {
        UserRole.superAdmin, UserRole.admin, UserRole.hrAdmin, UserRole.rhManager,
        UserRole.manager, UserRole.direction,
      };
      final canValidate = role != null &&
          (validators.contains(role) || (auth.user?.hasPermission('MANAGE_LEAVES') ?? false));
      final endpoint = canValidate ? '/conges' : '/conges/me';
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

  /// Soumet une demande. Renvoie true si elle a été acceptée par le serveur ;
  /// sinon le motif du refus (solde, chevauchement…) est affiché.
  Future<bool> submitRequest({
    required String typeConge,
    required DateTime dateDebut,
    required DateTime dateFin,
    String? motif,
  }) async {
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    return _run(
      () => _ref.read(apiServiceProvider).post<Map<String, dynamic>>(
        '/conges',
        data: {
          'typeConge': typeConge,
          'dateDebut': day(dateDebut),
          'dateFin': day(dateFin),
          'nombreJours': dateFin.difference(dateDebut).inDays + 1,
          'motif': motif,
        },
      ),
      success: 'Demande de congé envoyée.',
      failure: "La demande n'a pas pu être envoyée.",
    );
  }

  Future<bool> approve(int congeId) => _run(
        () => _ref.read(apiServiceProvider).post<void>('/conges/$congeId/approve'),
        success: 'Congé approuvé.',
        failure: "L'approbation a échoué.",
      );

  Future<bool> reject(int congeId, {String? commentaire}) => _run(
        () => _ref.read(apiServiceProvider).post<void>(
          '/conges/$congeId/reject',
          data: {'commentaire': commentaire},
        ),
        success: 'Demande refusée.',
        failure: 'Le refus a échoué.',
      );

  Future<bool> _run(Future<Object?> Function() call, {required String success, required String failure}) async {
    try {
      await call();
      _notify(success);
      await load();
      return true;
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      // 403 et 5xx sont déjà signalés par l'intercepteur
      if (status != 403 && (status == null || status < 500)) {
        _notify(ApiService.messageOf(e, failure), error: true);
      }
      return false;
    }
  }

  void _notify(String message, {bool error = false}) {
    rootScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFD64545) : null,
      ));
  }
}
