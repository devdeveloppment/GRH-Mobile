import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/fiche_paie.dart';

/// Paie de l'entreprise (RH / gestionnaire de paie).
final paieNotifierProvider = ChangeNotifierProvider.autoDispose<PaieNotifier>((ref) {
  final notifier = PaieNotifier(ref);
  unawaited(notifier.loadForPeriod(DateTime.now()));
  return notifier;
});

/// Bulletins de l'employé connecté uniquement (espace employé).
final myPaieNotifierProvider = ChangeNotifierProvider.autoDispose<PaieNotifier>((ref) {
  final notifier = PaieNotifier(ref, mineOnly: true);
  unawaited(notifier.loadForPeriod(DateTime.now()));
  return notifier;
});

class PaieNotifier extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Une requête peut se terminer après la destruction du notifier (déconnexion, changement d'écran).
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  PaieNotifier(this._ref, {this.mineOnly = false});

  final Ref _ref;
  final bool mineOnly;
  List<FichePaie> bulletins = <FichePaie>[];
  bool isLoading = false;
  String? errorMessage;
  DateTime selectedPeriod = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic> monthlySummary = {};

  // Computed properties
  double get totalGrossMass => bulletins.fold(0.0, (sum, b) => sum + b.salaireBrut);
  double get totalDeductions => bulletins.fold(0.0, (sum, b) => sum + (b.cotisations + b.impots));
  double get totalNetMass => bulletins.fold(0.0, (sum, b) => sum + b.salaireNet);

  Future<void> loadForPeriod(DateTime period) async {
    selectedPeriod = DateTime(period.year, period.month);
    isLoading = true;
    errorMessage = null;
    final cacheKey = mineOnly
        ? 'paie-me'
        : 'paie-${selectedPeriod.year}-${selectedPeriod.month}';
    
    // Charger du cache d'abord
    final cached = await _ref.read(cacheServiceProvider).readList(cacheKey);
    if (cached.isNotEmpty && bulletins.isEmpty) {
      bulletins = cached.map(FichePaie.fromJson).toList(growable: false);
    }
    notifyListeners();

    try {
      final api = _ref.read(apiServiceProvider);
      final response = mineOnly
          ? await api.get<Map<String, dynamic>>('/paie/me')
          : await api.get<Map<String, dynamic>>(
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
      
      // Sauvegarder le résumé mensuel
      monthlySummary = payload['summary'] as Map<String, dynamic>? ?? {};
      
      await _ref.read(cacheServiceProvider).writeList(
            cacheKey,
            bulletins.map((item) => item.toJson()).toList(growable: false),
          );
    } catch (e) {
      errorMessage = 'Erreur lors du chargement des bulletins';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> calculateAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final api = _ref.read(apiServiceProvider);
      await api.post<void>(
        '/paie/calculate',
        data: {
          'month': selectedPeriod.month,
          'year': selectedPeriod.year,
        },
      );
      await loadForPeriod(selectedPeriod);
    } catch (e) {
      errorMessage = 'Erreur lors du calcul de la paie';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> downloadPayslip(int payslipId, String employeeName) async {
    try {
      final api = _ref.read(apiServiceProvider);
      return api.downloadFile(
        '/paie/$payslipId/bulletin/pdf',
        'bulletin-${employeeName.toLowerCase().replaceAll(' ', '-')}-${selectedPeriod.year}-${selectedPeriod.month}.pdf',
      );
    } catch (e) {
      errorMessage = 'Erreur lors du téléchargement';
      notifyListeners();
      return null;
    }
  }

  Future<void> validatePayroll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final api = _ref.read(apiServiceProvider);
      await api.post<void>(
        '/paie/validate',
        data: {
          'month': selectedPeriod.month,
          'year': selectedPeriod.year,
        },
      );
      await loadForPeriod(selectedPeriod);
    } catch (e) {
      errorMessage = 'Erreur lors de la validation';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportPayrollCSV() async {
    try {
      final api = _ref.read(apiServiceProvider);
      return api.downloadFile(
        '/paie/export/csv?month=${selectedPeriod.month}&year=${selectedPeriod.year}',
        'paie-${selectedPeriod.year}-${selectedPeriod.month}.csv',
      );
    } catch (e) {
      errorMessage = 'Erreur lors de l\'export';
      notifyListeners();
      return null;
    }
  }
}
