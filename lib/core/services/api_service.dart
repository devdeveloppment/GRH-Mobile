import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
            baseUrl: dotenv.env['API_BASE_URL'] ?? 'https://api.grh-mobile.com/api',
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
          if (statusCode == 401) {
            await _secureStorage.delete(key: tokenStorageKey);
            await _secureStorage.delete(key: userStorageKey);
            onUnauthorized?.call();
            _showSnackBar('Votre session a expiré. Veuillez vous reconnecter.', isError: true);
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

  static List<String> _readCertificatePins() {
    return (dotenv.env['CERT_SHA256_PINS'] ?? '')
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
