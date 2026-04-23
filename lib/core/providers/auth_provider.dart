import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/core/services/cache_service.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final notifier = AuthNotifier(storage: storage);
  unawaited(notifier.restoreSession());
  return notifier;
});

class AuthNotifier extends ChangeNotifier {
  AuthNotifier({
    required FlutterSecureStorage storage,
  })  : _storage = storage,
        _apiService = ApiService(secureStorage: storage) {
    _idleDuration = Duration(
      minutes: int.tryParse(dotenv.env['AUTO_LOGOUT_MINUTES'] ?? '30') ?? 30,
    );
  }

  final FlutterSecureStorage _storage;
  final ApiService _apiService;
  late final Duration _idleDuration;

  Utilisateur? _user;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  Timer? _inactivityTimer;

  Utilisateur? get user => _user;
  String? get token => _token;
  UserRole? get role => _user?.role;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    final token = await _storage.read(key: ApiService.tokenStorageKey);
    final userJson = await _storage.read(key: ApiService.userStorageKey);

    if (token != null && userJson != null) {
      _token = token;
      _user = Utilisateur.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      _startInactivityTimer();
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data ?? <String, dynamic>{};
      final token = data['token'] as String?;
      final user = Utilisateur.fromJson(data['user'] as Map<String, dynamic>? ?? <String, dynamic>{
        'role': data['role'],
        'email': email,
      });

      if (token == null || token.isEmpty) {
        throw const FormatException('Le token JWT est absent de la réponse.');
      }

      _token = token;
      _user = user;

      await _storage.write(key: ApiService.tokenStorageKey, value: token);
      await _storage.write(
        key: ApiService.userStorageKey,
        value: jsonEncode(user.toJson()),
      );

      _startInactivityTimer();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Identifiants invalides ou compte inactif.';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _inactivityTimer?.cancel();
    _token = null;
    _user = null;
    await _storage.delete(key: ApiService.tokenStorageKey);
    await _storage.delete(key: ApiService.userStorageKey);
    notifyListeners();
  }

  void registerActivity() {
    if (!isAuthenticated) {
      return;
    }
    _startInactivityTimer();
  }

  Future<void> handleSessionExpired() async {
    await logout();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_idleDuration, () {
      unawaited(logout());
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final auth = ref.watch(authNotifierProvider);
  return ApiService(
    secureStorage: storage,
    onUnauthorized: auth.handleSessionExpired,
  );
});
