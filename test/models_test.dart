import 'package:flutter_test/flutter_test.dart';
import 'package:grh_mobile/shared/models/employe.dart';
import 'package:grh_mobile/shared/models/presence.dart';
import 'package:grh_mobile/shared/models/conge.dart';

void main() {
  group('Models', () {
    group('Employe', () {
      test('creates Employe from JSON', () {
        final json = {
          'id': 1,
          'matricule': 'EMP001',
          'nom': 'Dupont',
          'prenom': 'Jean',
          'email': 'jean@example.com',
          'statut': 'ACTIF',
          'poste': 'Manager',
          'service': 'IT',
          'typeContrat': 'CDI',
        };

        final employe = Employe.fromJson(json);
        expect(employe.matricule, 'EMP001');
        expect(employe.nom, 'Dupont');
        expect(employe.fullName, 'Jean Dupont');
      });

      test('converts Employe to JSON', () {
        final employe = Employe(
          matricule: 'EMP001',
          nom: 'Dupont',
          prenom: 'Jean',
          email: 'jean@example.com',
          statut: 'ACTIF',
          poste: 'Manager',
          service: 'IT',
          typeContrat: 'CDI',
        );

        final json = employe.toJson();
        expect(json['matricule'], 'EMP001');
        expect(json['email'], 'jean@example.com');
      });

      test('fullName is formatted correctly', () {
        final employe = Employe(
          matricule: 'EMP001',
          nom: 'Dupont',
          prenom: 'Jean',
          email: 'jean@example.com',
          statut: 'ACTIF',
          poste: 'Manager',
          service: 'IT',
          typeContrat: 'CDI',
        );

        expect(employe.fullName, 'Jean Dupont');
      });
    });

    group('Presence', () {
      test('creates Presence from JSON', () {
        final json = {
          'id': 1,
          'date': '2026-05-02',
          'statut': 'PRESENT',
          'employeId': 1,
        };

        final presence = Presence.fromJson(json);
        expect(presence.statut, 'PRESENT');
      });

      test('converts Presence to JSON', () {
        final now = DateTime.now();
        final presence = Presence(
          id: 1,
          date: now,
          statut: 'PRESENT',
          employeId: 1,
        );

        final json = presence.toJson();
        expect(json['statut'], 'PRESENT');
      });
    });

    group('Conge', () {
      test('creates Conge from JSON', () {
        final json = {
          'id': 1,
          'dateDebut': '2026-05-01',
          'dateFin': '2026-05-10',
          'nombreJours': 10,
          'typeConge': 'ANNUEL',
          'statut': 'EN_ATTENTE',
          'employe': {
            'matricule': 'EMP001',
            'nom': 'Dupont',
            'prenom': 'Jean',
            'email': 'jean@example.com',
            'statut': 'ACTIF',
            'poste': 'Manager',
            'service': 'IT',
            'typeContrat': 'CDI',
          },
        };

        final conge = Conge.fromJson(json);
        expect(conge.typeConge, 'ANNUEL');
        expect(conge.nombreJours, 10);
      });
    });
  });
}
