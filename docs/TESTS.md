# GRH-Mobile — Lancer les tests

Public visé : développeur ou testeur. Toujours contre une base de **démonstration** (profil `demo`,
données fictives) ; jamais contre une base contenant des données personnelles réelles.

## 1. Backend (Java 17, Docker requis pour Testcontainers)

```bash
cd backend
mvn verify          # 17 tests unitaires + 72 tests d'intégration (PostgreSQL réel en conteneur)
```

## 2. Flutter — tests unitaires

```bash
flutter test        # 50 tests
```

## 3. Comptes de test (jamais dans Git)

Copier `integration_test/test_accounts.env.example` vers un fichier **hors dépôt** et renseigner les
comptes de démonstration, plus `GRH_TEST_PLATFORM_EMAIL/PASSWORD` et `API_BASE_URL`
(ex. `http://10.0.2.2:8082/api` pour l'émulateur Android, `http://localhost:8082/api` pour le Web).

## 4. Android (émulateur ou téléphone)

```bash
flutter test integration_test/role_pages_audit_test.dart  -d <appareil> --dart-define-from-file=<fichier.env>
flutter test integration_test/parcours_ecriture_test.dart -d <appareil> --dart-define-from-file=<fichier.env>
flutter test integration_test/hors_ligne_test.dart        -d <appareil> --dart-define-from-file=<fichier.env>
```

Captures : ajouter `--dart-define=GRH_CAPTURES=true` ; le test écrit `GRH_CAPTURE <nom>` dans le journal,
qu'un script hôte transforme en `adb exec-out screencap`.

## 5. Web (Chrome) — NON EXÉCUTÉ à ce jour

Prérequis : ChromeDriver **de la même version que Chrome** (Chrome for Testing,
https://googlechromelabs.github.io/chrome-for-testing/), lancé sur le port 4444.
Le téléchargement automatique a été bloqué par la politique de sécurité de la session de développement :
à installer par une personne autorisée.

```bash
chromedriver --port=4444 &
# Le backend doit autoriser l'origine du test : CORS_ALLOWED_ORIGINS=http://localhost:<port>
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/parcours_ecriture_test.dart \
  -d chrome --dart-define-from-file=<fichier_web.env>
```

`test_driver/integration_test.dart` (fichier standard) :

```dart
import 'package:integration_test/integration_test_driver.dart';
Future<void> main() => integrationDriver();
```

Points à vérifier en plus sur le Web : affichage large (barre latérale fixe ≥ 1024 px), téléchargement des
exports (PDF/XLSX), stockage du jeton (le stockage « sécurisé » du navigateur est moins protégé).

## 6. Téléphone physique — NON RÉALISÉ (aucun appareil disponible)

Matériel : un téléphone Android 8 ou plus (idéalement un modèle d'entrée de gamme courant au Togo et un
modèle récent), câble USB, options développeur et « débogage USB » activés ; le PC et le téléphone sur le
même réseau que le backend de démonstration (ou `adb reverse tcp:8082 tcp:8082`).

Procédure :
1. `flutter devices` doit lister le téléphone ;
2. lancer les trois tests du § 4 avec `-d <id du téléphone>` et `API_BASE_URL=http://localhost:8082/api`
   après `adb reverse` ;
3. vérifications manuelles complémentaires : lecture des textes en plein soleil, rotation, clavier qui
   masque les champs, appareil photo et sélection de fichiers (justificatifs), ouverture des PDF,
   mode avion pendant la saisie d'une demande de congé puis retour du réseau (bandeau et envoi),
   fermeture forcée de l'application avec une opération en attente puis réouverture, réseau 3G lent
   (options développeur), notifications ;
4. noter modèle, version d'Android et résultats dans le rapport de recette.
