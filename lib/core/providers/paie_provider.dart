import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/fiche_paie.dart';

final paieNotifierProvider = ChangeNotifierProvider.autoDispose<PaieNotifier>((ref) {
  final notifier = PaieNotifier(ref);
  unawaited(notifier.loadForPeriod(DateTime.now()));
  return notifier;
});

class PaieNotifier extends ChangeNotifier {
  PaieNotifier(this._ref);

  final Ref _ref;
  List<FichePaie> bulletins = <FichePaie>[];
  bool isLoading = false;
  DateTime selectedPeriod = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> loadForPeriod(DateTime period) async {
    selectedPeriod = DateTime(period.year, period.month);
    isLoading = true;
    final cacheKey = 'paie-${selectedPeriod.year}-${selectedPeriod.month}';
    final cached = await _ref.read(cacheServiceProvider).readList(cacheKey);
    if (cached.isNotEmpty && bulletins.isEmpty) {
      bulletins = cached.map(FichePaie.fromJson).toList(growable: false);
    }
    notifyListeners();
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.get<Map<String, dynamic>>(
        '/paie',
        queryParameters: {
          'month': selectedPeriod.month,
          'year': selectedPeriod.year,
        },
      );
      final payload = response.data ?? <String, dynamic>{};
      final rawItems = payload['items'] as List<dynamic>? ??
          payload['data'] as List<dynamic>? ??
          <dynamic>[];
      bulletins = rawItems
          .whereType<Map<String, dynamic>>()
          .map(FichePaie.fromJson)
          .toList(growable: false);
      await _ref.read(cacheServiceProvider).writeList(
            cacheKey,
            bulletins.map((item) => item.toJson()).toList(growable: false),
          );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> calculateAll() async {
    final api = _ref.read(apiServiceProvider);
    await api.post<void>(
      '/paie/calculate',
      data: {
        'month': selectedPeriod.month,
        'year': selectedPeriod.year,
      },
    );
    await loadForPeriod(selectedPeriod);
  }

  Future<String?> downloadPayslip(int payslipId, String employeeName) async {
    final api = _ref.read(apiServiceProvider);
    return api.downloadFile(
      '/paie/$payslipId/bulletin/pdf',
      'bulletin-${employeeName.toLowerCase().replaceAll(' ', '-')}-${selectedPeriod.year}-${selectedPeriod.month}.pdf',
    );
  }
}
