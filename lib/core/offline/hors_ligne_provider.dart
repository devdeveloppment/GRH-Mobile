import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:grh_mobile/core/offline/file_attente_hors_ligne.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';

/// Stockage Hive chiffré (AES-256) ; la clé est conservée dans le stockage sécurisé du système
/// (Keystore Android). Sur le Web, le stockage sécurisé repose sur le navigateur : protection moindre.
class StockageHiveChiffre implements StockageFile {
  StockageHiveChiffre(this._secureStorage);

  static const _nomBoite = 'file_hors_ligne';
  static const _cleChiffrement = 'grh_mobile.cle_file_hors_ligne';
  final FlutterSecureStorage _secureStorage;
  Box<String>? _boite;

  Future<Box<String>> _ouvrir() async {
    if (_boite != null) return _boite!;
    var cle = await _secureStorage.read(key: _cleChiffrement);
    if (cle == null) {
      cle = base64UrlEncode(Hive.generateSecureKey());
      await _secureStorage.write(key: _cleChiffrement, value: cle);
    }
    _boite = await Hive.openBox<String>(_nomBoite, encryptionCipher: HiveAesCipher(base64Url.decode(cle)));
    return _boite!;
  }

  @override
  Future<List<String>> lire() async => (await _ouvrir()).values.toList();

  @override
  Future<void> ecrire(List<String> elements) async {
    final b = await _ouvrir();
    await b.clear();
    await b.addAll(elements);
  }
}

/// Envoi d'un élément avec sa clé d'idempotence ; traduit la réponse en résultat métier.
Future<ReponseEnvoi> envoyerAvecIdempotence(ApiService api, ElementEnAttente e) async {
  try {
    final options = Options(headers: {'Idempotency-Key': e.id});
    if (e.operation == OperationHorsLigne.noteFrais) {
      await api.client.post<dynamic>(e.operation.chemin, data: FormData.fromMap(e.donnees), options: options);
    } else {
      await api.client.post<dynamic>(e.operation.chemin, data: e.donnees, options: options);
    }
    return const ReponseEnvoi(ResultatEnvoi.succes);
  } on DioException catch (err) {
    final code = err.response?.statusCode;
    if (code == null || code >= 500 || code == 409 || code == 429) {
      // Pas de réponse, erreur serveur, opération en cours ou limitation : nouvel essai plus tard.
      return const ReponseEnvoi(ResultatEnvoi.reseauIndisponible);
    }
    if (code == 401) return const ReponseEnvoi(ResultatEnvoi.sessionInvalide);
    return ReponseEnvoi(ResultatEnvoi.refuse, ApiService.messageOf(err, 'Refusé par le serveur.'));
  }
}

/// Indique si une erreur correspond à une absence de réseau (et non à un refus du serveur).
bool estErreurReseau(Object e) =>
    e is DioException &&
    e.response == null &&
    (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.unknown);

final fileHorsLigneProvider = ChangeNotifierProvider<FileAttenteHorsLigne>((ref) {
  final file = FileAttenteHorsLigne(
    StockageHiveChiffre(ref.read(secureStorageProvider)),
    (e) => envoyerAvecIdempotence(ref.read(apiServiceProvider), e),
  );
  // Synchronisation : à la connexion, puis toutes les 30 secondes tant qu'il reste des éléments.
  void suivreSession() {
    final auth = ref.read(authNotifierProvider);
    file.utilisateurCourant = auth.isAuthenticated ? auth.user?.id : null;
    if (file.utilisateurCourant != null) unawaited(file.synchroniser());
  }

  ref.listen(authNotifierProvider, (_, __) => suivreSession());
  suivreSession();
  final minuterie = Timer.periodic(const Duration(seconds: 30), (_) {
    if (file.enAttente > 0) unawaited(file.synchroniser());
  });
  ref.onDispose(minuterie.cancel);
  return file;
});
