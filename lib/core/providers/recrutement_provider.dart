import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

// ─── Offres ──────────────────────────────────────────────────────────────────

final offresProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String?>(
  (ref, statut) async {
    final api = ref.read(apiServiceProvider);
    final query = statut != null ? '?statut=$statut' : '';
    final resp = await api.get<Map<String, dynamic>>('/offres$query');
    final raw = resp.data?['items'] as List? ?? [];
    return raw.whereType<Map<String, dynamic>>().toList();
  },
);

// ─── Candidatures ────────────────────────────────────────────────────────────

final candidaturesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, offreId) async {
    final api = ref.read(apiServiceProvider);
    final resp =
        await api.get<Map<String, dynamic>>('/offres/$offreId/candidatures');
    final raw = resp.data?['items'] as List? ?? [];
    return raw.whereType<Map<String, dynamic>>().toList();
  },
);

// ─── Notifier ────────────────────────────────────────────────────────────────

class RecrutementNotifier extends StateNotifier<bool> {
  RecrutementNotifier(this._api) : super(false);

  final ApiService _api;

  Future<bool> createOffre(Map<String, dynamic> body) async {
    try {
      await _api.post<Map<String, dynamic>>('/offres', data: body);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatutOffre(int id, String statut) async {
    try {
      await _api.put<Map<String, dynamic>>('/offres/$id/statut?statut=$statut');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> postuler(int offreId, Map<String, dynamic> body) async {
    try {
      await _api.post<Map<String, dynamic>>('/offres/$offreId/candidatures',
          data: body);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatutCandidature(int id, String statut) async {
    try {
      await _api.put<Map<String, dynamic>>(
          '/candidatures/$id/statut?statut=$statut');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> planifierEntretien(int candidatureId, Map<String, dynamic> body) async {
    try {
      await _api.post<Map<String, dynamic>>(
          '/candidatures/$candidatureId/entretiens',
          data: body);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Retourne le matricule du nouvel employé créé.
  Future<String> embaucher(int candidatureId, {
    required String poste,
    required String service,
    required String typeContrat,
    required double salaire,
  }) async {
    final resp = await _api.post<Map<String, dynamic>>(
      '/candidatures/$candidatureId/embaucher',
      queryParameters: {
        'poste': poste,
        'service': service,
        'typeContrat': typeContrat,
        if (salaire > 0) 'salaire': salaire,
      },
    );
    return resp.data?['matricule'] as String? ?? '';
  }

  Future<void> downloadCv(int candidatureId) async {
    final resp = await _api.client.get<List<int>>(
      '/api/candidatures/$candidatureId/cv',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = resp.data;
    if (bytes == null || bytes.isEmpty) throw Exception('Fichier vide');
    final dir = await getTemporaryDirectory();
    final disposition = resp.headers.value('content-disposition') ?? '';
    final nameMatch = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
    final filename = nameMatch?.group(1) ?? 'cv.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
  }
}

final recrutementNotifierProvider =
    StateNotifierProvider<RecrutementNotifier, bool>(
  (ref) => RecrutementNotifier(ref.read(apiServiceProvider)),
);
