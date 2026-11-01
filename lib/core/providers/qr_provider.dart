import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/shared/models/qr_code_model.dart';

final qrNotifierProvider =
    ChangeNotifierProvider.autoDispose<QrNotifier>((ref) {
  final notifier = QrNotifier(ref);
  unawaited(notifier.load());
  // Le QR de pointage est signé et expire après 90 s : on le renouvelle toutes les 60 s.
  final timer = Timer.periodic(const Duration(seconds: 60), (_) => notifier.refreshSilently());
  ref.onDispose(timer.cancel);
  return notifier;
});

class QrNotifier extends ChangeNotifier {
  QrNotifier(this._ref);

  final Ref _ref;
  QrCodeModel? qrCode;
  bool isLoading = false;
  bool isRegenerating = false;
  bool isScanLoading = false;
  String? error;
  String? scanError;
  Map<String, dynamic>? lastScanResult;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.get<Map<String, dynamic>>('/qrcodes/me');
      if (response.data != null) {
        qrCode = QrCodeModel.fromJson(response.data!);
      }
    } catch (e) {
      error = ApiService.messageOf(e, 'Impossible de charger votre QR code.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Renouvelle le QR dynamique sans afficher d'indicateur de chargement.
  Future<void> refreshSilently() async {
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.get<Map<String, dynamic>>('/qrcodes/me');
      if (response.data != null) {
        qrCode = QrCodeModel.fromJson(response.data!);
        error = null;
        notifyListeners();
      }
    } catch (_) {
      // nouvel essai au prochain cycle
    }
  }

  Future<void> regenerate() async {
    isRegenerating = true;
    error = null;
    notifyListeners();
    try {
      final api = _ref.read(apiServiceProvider);
      final response =
          await api.post<Map<String, dynamic>>('/qrcodes/regenerate');
      if (response.data != null) {
        qrCode = QrCodeModel.fromJson(response.data!);
      }
    } catch (e) {
      error = 'Erreur lors de la régénération du QR Code.';
    } finally {
      isRegenerating = false;
      notifyListeners();
    }
  }

  /// Scan QR : envoie le token au backend et enregistre la présence
  Future<Map<String, dynamic>?> scanQr(String rawQrData) async {
    isScanLoading = true;
    scanError = null;
    notifyListeners();
    try {
      String token;
      try {
        final decoded = jsonDecode(rawQrData) as Map<String, dynamic>;
        token = decoded['token'] as String;
      } catch (_) {
        token = rawQrData.trim();
      }

      final api = _ref.read(apiServiceProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/presences/scan',
        data: {'token': token},
      );
      lastScanResult = response.data;
      return response.data;
    } catch (e) {
      scanError = e.toString();
      return null;
    } finally {
      isScanLoading = false;
      notifyListeners();
    }
  }
}
