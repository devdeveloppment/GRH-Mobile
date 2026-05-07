import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';

final reportNotifierProvider =
    ChangeNotifierProvider.autoDispose<ReportNotifier>((ref) {
  final notifier = ReportNotifier(ref);
  unawaited(notifier.loadServices());
  return notifier;
});

class ReportNotifier extends ChangeNotifier {
  ReportNotifier(this._ref);

  final Ref _ref;
  bool isLoading = false;
  String? errorMessage;
  List<String> services = [];

  Future<void> loadServices() async {
    try {
      final api = _ref.read(apiServiceProvider);
      final response =
          await api.get<Map<String, dynamic>>('/services');
      final items =
          response.data?['items'] as List<dynamic>? ?? [];
      services = items
          .whereType<Map<String, dynamic>>()
          .map((s) => s['nom'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> generateAndDownload({
    required String type,
    required DateTime debut,
    required DateTime fin,
    required String format,
    String? service,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final api = _ref.read(apiServiceProvider);
      final debutStr =
          '${debut.year}-${debut.month.toString().padLeft(2, '0')}-${debut.day.toString().padLeft(2, '0')}';
      final finStr =
          '${fin.year}-${fin.month.toString().padLeft(2, '0')}-${fin.day.toString().padLeft(2, '0')}';
      final ext = format.toLowerCase() == 'csv' ? 'csv' : 'pdf';
      final filename =
          'rapport-${type.toLowerCase()}-$debutStr.$ext';

      final body = <String, dynamic>{
        'type': type,
        'debut': debutStr,
        'fin': finStr,
        'format': format,
        if (service != null && service.isNotEmpty) 'service': service,
      };

      return await api.postAndDownload('/reports/generate', body, filename);
    } catch (e) {
      errorMessage = 'Erreur lors de la génération du rapport.';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportLegacy(String format) async {
    try {
      final api = _ref.read(apiServiceProvider);
      return api.downloadFile(
        '/reports/export?format=$format',
        'rapport-rh.${format == 'excel' ? 'xlsx' : 'pdf'}',
      );
    } catch (e) {
      errorMessage = 'Export impossible.';
      notifyListeners();
      return null;
    }
  }
}
