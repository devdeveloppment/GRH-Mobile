# GRH-Mobile

Plateforme de gestion des ressources humaines pour les PME (Togo, puis Afrique de l'Ouest).
Backend **Spring Boot 3 / PostgreSQL / Flyway**, application **Flutter** (Web et Android).

> État du produit : en développement, **non prêt pour la production**.
> Voir `RAPPORT_FINAL_REPRISE_ET_FINALISATION_GRH_MOBILE.md` pour l'état détaillé.

## Fonctionnalités principales

- Authentification JWT, 10 rôles, permissions modifiables, journal d'audit
- Employés, départements, postes, contrats (alertes d'expiration), documents
- Présences (pointage par QR code), congés (demande et validation), heures de travail
- Paie : calcul et bulletins PDF. **Les règles légales togolaises (CNSS, IRPP) ne sont pas encore
  configurées : elles attendent une validation par un expert-comptable.** Ne pas utiliser pour une paie réelle.
- Recrutement (offres publiques, candidatures avec CV, entretiens, embauche), formations, évaluations
- Espace employé (web et mobile), notifications, tableaux de bord, rapports

## Prérequis

| Outil | Version testée |
|---|---|
| Java (JDK) | 17 |
| Maven | 3.9 |
| PostgreSQL | 15 à 17 (ou Docker) |
| Flutter | 3.38 (Dart 3.10) |
| Docker | Desktop récent (uniquement pour les tests d'intégration backend) |

## Installation depuis un clone neuf

### 1. Base de données

```bash
docker compose up -d postgres        # PostgreSQL sur localhost:5432 (base grh_mobile, utilisateur grh)
```

### 2. Backend

```bash
cd backend
cp .env.example .env                 # puis renseigner JWT_SECRET (au moins 32 caractères aléatoires)
```

Variables principales (voir `backend/.env.example`) : `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`,
`JWT_SECRET`, `SERVER_PORT`, `BOOTSTRAP_ADMIN_EMAIL`, `BOOTSTRAP_ADMIN_PASSWORD`.

Exporter ces variables dans votre shell (Spring Boot ne lit pas `.env` tout seul), puis :

```bash
mvn spring-boot:run                                          # base vide : seul le compte admin est créé
mvn spring-boot:run -Dspring-boot.run.profiles=demo          # + données FICTIVES de démonstration
```

- Les migrations Flyway (V1 à V6, puis V10 à V27 ; V7 à V9 n'ont jamais existé) s'appliquent automatiquement.
- Compte administrateur initial : `BOOTSTRAP_ADMIN_EMAIL`. Sans `BOOTSTRAP_ADMIN_PASSWORD`, un mot de passe
  temporaire est affiché dans les logs et doit être changé à la première connexion.
- Profil `demo` : comptes de démonstration fictifs, mot de passe défini par `DEMO_PASSWORD` (sinon mot de
  passe temporaire affiché dans les logs). **Le profil `demo` refuse de démarrer avec le profil `prod`.**

### 3. Application Flutter

```bash
flutter pub get
cp .env.example .env                 # adapter API_BASE_URL (ex. http://localhost:8080/api)
flutter run -d chrome --dart-define-from-file=.env
flutter run -d <id-android>  --dart-define-from-file=.env
```

- `.env.example` (versionné) fournit les valeurs par défaut ; `--dart-define-from-file=.env` les surcharge.
- Le vrai `.env` n'est **jamais** versionné ni embarqué dans l'application.
- Sur l'émulateur Android, `localhost` est automatiquement remplacé par `10.0.2.2`.

## Tests

```bash
# Backend : tests unitaires
cd backend && mvn test
# Backend : tests unitaires + intégration (PostgreSQL via Testcontainers, Docker requis)
cd backend && mvn verify

# Flutter : analyse et tests unitaires
flutter analyze
flutter test

# Flutter : parcours par rôle sur un appareil (comptes de DÉMO uniquement)
cp integration_test/test_accounts.env.example integration_test/test_accounts.env   # à remplir, ignoré par Git
flutter test integration_test/role_pages_audit_test.dart -d <appareil> \
  --dart-define-from-file=integration_test/test_accounts.env
```

## Sécurité

- Ne jamais versionner : `.env`, `backend/.env`, `android/local.properties`, keystores, `key.properties`,
  `integration_test/test_accounts.env`, le dossier `uploads/`.
- Ne jamais utiliser de données personnelles réelles dans les tests ou les démonstrations.
