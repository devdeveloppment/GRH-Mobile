import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration de l'application.
///
/// Ordre de priorité :
/// 1. valeurs passées à la compilation (`--dart-define` ou
///    `--dart-define-from-file=.env`) ;
/// 2. valeurs de `.env.example` (versionné, chargé au démarrage) ;
/// 3. valeur par défaut codée ici.
///
/// Le vrai `.env` n'est jamais embarqué comme asset : il reste local.
class AppConfig {
  const AppConfig._();

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _certPins = String.fromEnvironment('CERT_SHA256_PINS');
  static const String _autoLogout = String.fromEnvironment('AUTO_LOGOUT_MINUTES');

  static String get apiBaseUrl =>
      _pick(_apiBaseUrl, 'API_BASE_URL', 'https://api.grh-mobile.com/api');

  static String get certSha256Pins => _pick(_certPins, 'CERT_SHA256_PINS', '');

  static int get autoLogoutMinutes =>
      int.tryParse(_pick(_autoLogout, 'AUTO_LOGOUT_MINUTES', '30')) ?? 30;

  static String _pick(String compiled, String key, String fallback) {
    if (compiled.isNotEmpty) return compiled;
    final fromFile = dotenv.isInitialized ? dotenv.env[key] : null;
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
    return fallback;
  }
}
