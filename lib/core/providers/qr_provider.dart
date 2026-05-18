import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/qr_code_model.dart';

final qrNotifierProvider =
    ChangeNotifierProvider.autoDispose<QrNotifier>((ref) {
  final notifier = QrNotifier(ref);
  unawaited(notifier.load());
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
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
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
