import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:grh_mobile/core/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grh_mobile/core/constants/app_globals.dart';

import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';
import 'security_adapter_stub.dart' if (dart.library.io) 'security_adapter_io.dart';

class ApiService {
  ApiService({
    required FlutterSecureStorage secureStorage,
    this.onUnauthorized,
  })  : _secureStorage = secureStorage,
        _dio = Dio(
          BaseOptions(
            baseUrl: _resolveBaseUrl(),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    configureSecurityAdapter(_dio, _readCertificatePins());
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: tokenStorageKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final isLogin = error.requestOptions.path.endsWith('/auth/login');
          // Un 401 sur un ancien jeton (requête partie avant une déconnexion/reconnexion)
          // ne doit pas effacer la nouvelle session.
          final sentAuth = error.requestOptions.headers['Authorization'];
          final current = await _secureStorage.read(key: tokenStorageKey);
          final staleToken = current != null && sentAuth != 'Bearer $current';
          if (statusCode == 401 && !isLogin && staleToken) {
            // Rien à faire : la session courante est différente.
          } else if (statusCode == 401 && !isLogin) {
            await _secureStorage.delete(key: tokenStorageKey);
            await _secureStorage.delete(key: userStorageKey);
            onUnauthorized?.call();
            _showSnackBar('Votre session a expiré. Veuillez vous reconnecter.', isError: true);
          } else if (statusCode == 403) {
            _showSnackBar(
              "Vous n'avez pas les droits nécessaires pour cette action.",
              isError: true,
            );
          } else if (statusCode != null && statusCode >= 500) {
            _showSnackBar(
              error.response?.data?['message']?.toString() ??
                  'Le service est momentanément indisponible.',
              isError: true,
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  static const String tokenStorageKey = 'grh_mobile.jwt';
  static const String userStorageKey = 'grh_mobile.user';

  static String _resolveBaseUrl() {
    String url = AppConfig.apiBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (url.contains('localhost')) url = url.replaceAll('localhost', '10.0.2.2');
      if (url.contains('127.0.0.1')) url = url.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final VoidCallback? onUnauthorized;

  Dio get client => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<String?> downloadFile(String path, String filename) async {
    final response = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    return saveFileBytes(bytes, filename);
  }

  Future<Response<T>> postFormData<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post<T>(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<String?> postAndDownload(
    String path,
    Map<String, dynamic> data,
    String filename,
  ) async {
    final response = await _dio.post<List<int>>(
      path,
      data: data,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) return null;
    return saveFileBytes(bytes, filename);
  }

  /// Message lisible pour l'utilisateur à partir d'une erreur d'appel API.
  static String messageOf(Object error, [String fallback = 'Une erreur est survenue.']) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message']?.toString();
        final details = data['details']?.toString();
        if (message != null && message.isNotEmpty) {
          return details != null && details.isNotEmpty && details != 'null'
              ? '$message $details'
              : message;
        }
        final legacy = data['error']?.toString();
        if (legacy != null && legacy.isNotEmpty) return legacy;
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Serveur injoignable. Vérifiez votre connexion.';
      }
    }
    return fallback;
  }

  static List<String> _readCertificatePins() {
    return AppConfig.certSha256Pins
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? const Color(0xFFD64545) : null,
          content: Text(message),
        ),
      );
  }
}
