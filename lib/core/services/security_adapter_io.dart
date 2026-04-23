import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureSecurityAdapter(Dio dio, List<String> certificatePins) {
  if (certificatePins.isEmpty) {
    return;
  }

  final adapter = IOHttpClientAdapter();
  adapter.createHttpClient = () {
    final client = HttpClient(context: SecurityContext(withTrustedRoots: true));
    client.badCertificateCallback = (X509Certificate certificate, String host, int port) {
      final String fingerprint = base64.encode(sha256.convert(certificate.der).bytes);
      return certificatePins.contains(fingerprint);
    };
    return client;
  };
  dio.httpClientAdapter = adapter;
}
