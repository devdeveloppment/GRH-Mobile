import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';

final reportNotifierProvider =
    ChangeNotifierProvider.autoDispose<ReportNotifier>((ref) {
  return ReportNotifier(ref);
});

class ReportNotifier extends ChangeNotifier {
  ReportNotifier(this._ref);

  final Ref _ref;
  bool isLoading = false;
  String? errorMessage;
  List<Map<String, dynamic>> reports = [];

  Future<void> loadReports({
    String? type = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final api = _ref.read(apiServiceProvider);
      final params = <String, dynamic>{
        'type': type,
      };
      if (startDate != null) params['startDate'] = startDate.toIso8601String();
      if (endDate != null) params['endDate'] = endDate.toIso8601String();

      final response = await api.get<Map<String, dynamic>>(
        '/reports',
        queryParameters: params,
      );

      reports = List<Map<String, dynamic>>.from(
        response.data?['items'] as List<dynamic>? ?? [],
      );
    } catch (e) {
      errorMessage = 'Erreur lors du chargement des rapports';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<int>?> exportReportPDF({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final api = _ref.read(apiServiceProvider);
      final params = <String, dynamic>{'type': reportType};
      if (startDate != null) params['startDate'] = startDate.toIso8601String();
      if (endDate != null) params['endDate'] = endDate.toIso8601String();

      final bytes = await api.downloadFile(
        '/reports/export?${_buildQueryString(params)}',
        'rapport_$reportType.pdf',
      );
      
      return bytes != null ? bytes.codeUnits : null;
    } catch (e) {
      errorMessage = 'Erreur lors de l\'export du PDF';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> generateReport({
    required String reportType,
    required Map<String, dynamic> filters,
  }) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/reports/generate',
        data: {
          'type': reportType,
          'filters': filters,
        },
      );
      return response.data ?? {};
    } catch (e) {
      errorMessage = 'Erreur lors de la génération du rapport';
      return {};
    }
  }

  String _buildQueryString(Map<String, dynamic> params) {
    final entries = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .toList();
    return entries.join('&');
  }
}
