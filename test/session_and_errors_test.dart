import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/shared/models/employe.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';

void main() {
  group('Utilisateur', () {
    test('lit les permissions et le changement de mot de passe obligatoire', () {
      final user = Utilisateur.fromJson({
        'id': 4,
        'nom': 'Doe',
        'prenom': 'Jane',
        'email': 'jane@test.local',
        'role': 'MANAGER',
        'doitChangerMotDePasse': true,
        'permissions': ['MANAGE_LEAVES'],
      });

      expect(user.doitChangerMotDePasse, isTrue);
      expect(user.hasPermission('MANAGE_LEAVES'), isTrue);
      expect(user.hasPermission('MANAGE_PAIE'), isFalse);
    });

    test("l'administrateur dispose de toutes les permissions", () {
      final admin = Utilisateur.fromJson({'id': 1, 'role': 'ADMIN'});
      expect(admin.hasPermission('MANAGE_PAIE'), isTrue);
    });

    test('toJson / fromJson conserve la session et copyWith lève le drapeau', () {
      final user = Utilisateur.fromJson({
        'id': 2,
        'role': 'EMPLOYEE',
        'doitChangerMotDePasse': true,
        'permissions': ['VIEW_REPORTS'],
      });
      final restored = Utilisateur.fromJson(user.toJson());
      expect(restored.permissions, ['VIEW_REPORTS']);
      expect(restored.copyWith(doitChangerMotDePasse: false).doitChangerMotDePasse, isFalse);
    });
  });

  group('Employe', () {
    test('salaire masqué (null) et rattachements organisationnels', () {
      final e = Employe.fromJson({
        'matricule': 'GRH-1',
        'nom': 'Doe',
        'prenom': 'John',
        'email': 'john@test.local',
        'poste': 'Comptable',
        'service': 'Finance',
        'typeContrat': 'CDI',
        'salaire': null,
        'departementId': 3,
        'managerNom': 'Ama Tossou',
      });
      expect(e.salaire, isNull);
      expect(e.departementId, 3);
      expect(e.managerNom, 'Ama Tossou');
    });
  });

  group('ApiService.messageOf', () {
    DioException errorWith(Map<String, dynamic> body, int status) {
      final options = RequestOptions(path: '/conges');
      return DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: status, data: body),
      );
    }

    test('restitue le message métier du serveur', () {
      final e = errorWith({'message': 'Une demande de congé existe déjà sur cette période.'}, 400);
      expect(ApiService.messageOf(e), 'Une demande de congé existe déjà sur cette période.');
    });

    test('ajoute les détails de validation', () {
      final e = errorWith({'message': 'Validation échouée.', 'details': 'Le nom est obligatoire.'}, 400);
      expect(ApiService.messageOf(e), 'Validation échouée. Le nom est obligatoire.');
    });

    test('utilise le message par défaut sinon', () {
      expect(ApiService.messageOf(Exception('x'), 'Par défaut'), 'Par défaut');
    });
  });
}
