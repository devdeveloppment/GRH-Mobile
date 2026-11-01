# AUDIT GLOBAL — PLATEFORME RH PME « GRH-Mobile »

| | |
|---|---|
| **Date** | 31/10/2026 |
| **Périmètre** | Dépôt `GRH-Mobile` (branche `main`, état du répertoire de travail incluant les modifications non commitées) |
| **Nature** | Audit technique, fonctionnel, sécurité et UX — **lecture seule, aucune modification du code source** |
| **Méthode** | Analyse statique du code (backend Spring Boot + frontend Flutter), compilation, tentative d'exécution des tests. **Aucune exécution de l'application, aucun test manuel, aucune base de données utilisée.** |

> **Légende des niveaux de preuve** utilisée dans ce rapport :
> - **[CODE]** : constaté par lecture du code source (avec référence fichier:ligne) ;
> - **[BUILD]** : vérifié par compilation ;
> - **[AUTO]** : vérifié par test automatisé exécuté ;
> - **[NV]** : non vérifiable dans cet environnement.
>
> Aucune fonctionnalité n'a été testée manuellement ni visuellement : l'application n'a pas pu être lancée (pas de base PostgreSQL disponible, mémoire système insuffisante — voir §I). En conséquence, **aucune fonctionnalité n'est classée « Fonctionnel et vérifié »**.

---

## A. PRÉSENTATION GÉNÉRALE

### A.1 Compréhension du projet

GRH-Mobile est un SIRH (Système d'Information RH) présenté dans `pubspec.yaml` comme une « plateforme GRH B2B/SaaS pour les PME togolaises ». Il couvre l'administration du personnel, les présences (pointage GPS et QR code), les congés, la paie simplifiée, le recrutement, les évaluations, les formations, les tableaux de bord et les rapports. Les montants sont exprimés en FCFA.

### A.2 Objectifs métier (déduits du code)

- Centraliser les dossiers des employés d'une PME ;
- Dématérialiser le pointage (mobile + QR) et les demandes de congé ;
- Produire des bulletins de paie et des exports ;
- Donner à la direction et aux RH des indicateurs (effectif, présence, masse salariale, turnover) ;
- Offrir un espace libre-service à l'employé (congés, présences, paie, QR personnel).

### A.3 Architecture technique

```
┌──────────────────────────────┐   HTTPS + JWT (Bearer)    ┌──────────────────────────────────┐
│  Frontend Flutter (lib/)     │ ───────────────────────▶  │ Backend Spring Boot 3 (backend/) │
│  Android / iOS / Web / Desk. │   Dio + intercepteur      │  Controllers → Services → JPA    │
│  Riverpod (state)            │   (api_service.dart)      │  Spring Security (JWT stateless) │
│  go_router (garde de rôles)  │                           │  Flyway (V1…V25)                 │
│  flutter_secure_storage      │                           │  OpenPDF / Apache POI (exports)  │
└──────────────────────────────┘                           └───────────────┬──────────────────┘
                                                                           │ JDBC
                                                              ┌────────────▼────────────┐
                                                              │ PostgreSQL               │
                                                              │ + fichiers locaux        │
                                                              │   uploads/photos, /cv    │
                                                              └──────────────────────────┘
```

- **Backend** : `backend/src/main/java/com/grhmobile` — 21 contrôleurs, 18 services, 24 entités, 23 dépôts, 25 migrations Flyway, Java 17, Maven.
- **Frontend** : `lib/` — 29 écrans (`features/`), 19 providers Riverpod (`core/providers/`), 14 modèles, 18 widgets partagés (~19 500 lignes dans `features/`).
- **Déploiement** : `docker-compose.yml`, `backend/Dockerfile`, profil `application-aws.yml` (S3/CloudFront déclarés, non utilisés dans le code — stockage local uniquement).
- **Communication** : REST JSON ; base URL lue dans `.env` (`API_BASE_URL`, défaut `https://api.grh-mobile.com/api`) ; épinglage de certificat optionnel (`CERT_SHA256_PINS`, `security_adapter_io.dart`) ; déconnexion automatique après inactivité (`auth_provider.dart`, `AUTO_LOGOUT_MINUTES`).

### A.4 Technologies

| Couche | Technologies |
|---|---|
| Frontend | Flutter ≥3.22 / Dart ≥3.4, flutter_riverpod 2.5, go_router 13, dio 5, fl_chart, mobile_scanner, qr_flutter, file_picker, hive, flutter_dotenv |
| Backend | Spring Boot 3, Spring Security, JJWT, Spring Data JPA/Hibernate, Flyway, PostgreSQL, OpenPDF, Apache POI, springdoc-openapi, Actuator |
| Outillage | Maven 3.9, Docker Compose. **Pas de CI** (`.github/` sans workflow). |

### A.5 Profils utilisateurs (`enums/Role.java`)

| Rôle | Responsabilité déclarée | Écran d'accueil |
|---|---|---|
| SUPER_ADMIN | « accès total multi-entreprise » | Console admin |
| ADMIN | administrateur de l'instance | Console admin |
| HR_ADMIN | RH senior | Dashboard RH |
| RH_MANAGER | RH opérationnel | Dashboard RH |
| PAYROLL_OFFICER | module paie | Paie |
| MANAGER | manager d'équipe | Dashboard manager |
| RECRUITER | recrutement | Recrutement |
| TRAINER | formations | Formations |
| EMPLOYEE | libre-service | Espace employé |
| DIRECTION | lecture tableaux de bord | Dashboard direction |

### A.6 Multi-entreprise

**Non implémenté [CODE].** Aucune entité `Entreprise`/`Company`/`Tenant`, aucune colonne d'appartenance dans les migrations, aucun filtrage par société. La recherche `entreprise|company|tenant` ne trouve qu'un commentaire dans `Role.java:4`. L'application est **mono-instance / mono-entreprise**. Si un usage SaaS multi-PME est visé (cf. description du projet et rôle SUPER_ADMIN), l'architecture actuelle ne le permet pas : toutes les données seraient partagées. **→ Confirmation métier requise** sur le modèle de déploiement (une instance par PME, ou SaaS mutualisé).

---

## B. CARTOGRAPHIE FONCTIONNELLE

| # | Module | Rôle métier | Backend (contrôleur / service) | Frontend (écran) |
|---|---|---|---|---|
| 1 | Authentification | Connexion, session, mot de passe | `AuthController`, `AuthService`, `security/*`, `ProfileController` | `auth/login_screen.dart`, `profile/profile_screen.dart` |
| 2 | Utilisateurs, rôles, permissions | Comptes, rôles, matrice de permissions, paramètres | `AdminController`, `PermissionController` | `admin/admin_users_screen.dart`, `admin_roles_screen.dart`, `admin_settings_screen.dart` |
| 3 | Employés / dossiers du personnel | Fiche, recherche, archivage, documents, compétences | `EmployeeController`, `EmployeeService` | `employees/employee_list_screen.dart`, `employee_detail_screen.dart` |
| 4 | Organisation | Départements, services, postes, organigramme | `DepartementController`, `ServiceController`, `PosteController` | `departments/…`, `postes/…` |
| 5 | Contrats | Contrats, statut, échéances | `ContratController`, `ContratService` | `contrats/contrats_screen.dart` |
| 6 | Recrutement | Offres, candidatures, CV, entretiens, embauche | `RecrutementController`, `RecrutementService`, `FileStorageService` | `recrutement/recrutement_screen.dart`, `candidatures_screen.dart`, `postuler_screen.dart` |
| 7 | Congés | Demande, approbation, solde | `CongeController`, `CongeService` | `conges/conge_request_screen.dart`, espace employé, dashboard manager |
| 8 | Présences | Pointage GPS / QR, absences, justification | `PresenceController`, `PresenceService`, `QrCodeController`, `QrCodeService` | `presences/…`, `qr/employee_qr_screen.dart`, `qr/qr_scanner_screen.dart` |
| 9 | Paie | Calcul, validation, bulletin PDF, export CSV | `PaieController`, `PaieService` | `paie/paie_calculation_screen.dart` |
| 10 | Évaluations | Évaluations, objectifs | `EvaluationController`, `EvaluationService` | `evaluations/evaluations_screen.dart` |
| 11 | Formations | Sessions, inscriptions, participation | `FormationController`, `FormationService` | `formations/formations_screen.dart` |
| 12 | Notifications | Alertes in-app | `NotificationController`, `NotificationService` | `notifications/notifications_screen.dart` |
| 13 | Tableaux de bord | KPI RH / direction / admin / manager / employé | `DashboardController`, `DashboardService`, `AdminController#/stats` | `dashboard/*.dart` (6 écrans) |
| 14 | Rapports | Exports PDF / Excel / CSV | `ReportController`, `ReportService` | `rapports/reports_hub_screen.dart` |
| 15 | Journal d'audit | Traçabilité | `AuditLogController`, `AuditAspect`, `AuditLogService` | `audit/audit_log_screen.dart` |

**Modules absents [CODE]** : gestion multi-entreprises, horaires/plannings, heures supplémentaires, primes et indemnités variables, carrières/promotions, sanctions disciplinaires, import de données, mot de passe oublié.

### Relations entre modules

- **Employé** est le pivot : relié à `Utilisateur` (1-1), `ServiceEntity`, `Poste`, `Departement`, `manager` (auto-référence), et parent de Présences, Congés, Fiches de paie, Contrats, Documents, Compétences, Évaluations, Objectifs, Participations aux formations, QR code.
- **Recrutement → Employé** : `RecrutementService.embaucher` crée l'employé + son compte via `EmployeeService.create`.
- **Congés → Employé** : l'approbation décrémente `Employe.soldeConge` et notifie l'employé.
- **Paie → Employé** : le calcul utilise uniquement `Employe.salaireBrutBase` (aucun lien avec présences, congés sans solde ou contrats).
- **Présences ↔ QR** : le scan d'un jeton `EmployeQrCode` crée/complète la présence du jour.
- **Notifications** : générées par Congés (décision), Paie (bulletin), Présences (scan QR).
- **Dashboard / Rapports** : agrègent Employés, Présences, Congés, Paie.
- **Lien rompu** : les FK `employes.poste_id / departement_id / manager_id` (V18) existent mais **ne sont jamais renseignées** par l'API employé (voir AN-17) ; Départements/Postes vivent donc indépendamment des employés, qui utilisent encore les champs texte `poste` et `service`.

---

## C. ÉTAT DES FONCTIONNALITÉS

Aucune fonctionnalité n'a pu être exécutée ; le statut le plus favorable possible est donc « Fonctionnel mais partiellement vérifié » (code cohérent de bout en bout front → API → persistance, compilé, non exécuté).

| # | Module | Fonctionnalité | État constaté | Preuve / Observation | Action recommandée |
|---|---|---|---|---|---|
| 1 | Auth | Connexion e-mail / mot de passe (JWT) | Fonctionnel mais partiellement vérifié | `AuthService.login`, `JwtService`, `login_screen.dart` [CODE][BUILD] | Ajouter limitation des tentatives (AN-22) |
| 2 | Auth | Mot de passe oublié | Non implémenté | Lien `onTap: () {}` — `login_screen.dart:123` ; aucun endpoint | Implémenter ou masquer |
| 3 | Auth | Changement de mot de passe | Fonctionnel mais partiellement vérifié | `ProfileController#changePassword` + `profile_screen.dart` | Forcer le changement au 1er login (AN-06) |
| 4 | Auth | Déconnexion automatique par inactivité | Fonctionnel mais partiellement vérifié | `auth_provider.dart:159` (timer client) | Doubler par expiration serveur plus courte |
| 5 | Auth | Révocation / rafraîchissement de jeton | Non implémenté | JWT 480 min, pas de refresh ni liste noire | Voir AN-07 |
| 6 | Utilisateurs | CRUD comptes (admin) | Partiellement fonctionnel | `AdminController` : pas de validation, `Role.valueOf` non contrôlé, SUPER_ADMIN exclu par `hasRole('ADMIN')` | AN-08 |
| 7 | Utilisateurs | Matrice de permissions dynamique | Non fonctionnel (simulé) | Stockée/éditée (`PermissionController`) mais `PermissionRepository` utilisé nulle part ailleurs : aucune règle appliquée | AN-27 |
| 8 | Admin | Paramètres système | Non fonctionnel (simulé) | `AppSettingRepository` lu/écrit uniquement par `AdminController` ; aucun paramètre consommé | AN-27 |
| 9 | Employés | Liste, recherche, filtres, pagination | Fonctionnel mais partiellement vérifié | `EmployeeService.search` (Page Spring) ↔ `employee_provider.dart:80` | Restreindre l'accès (AN-03) |
| 10 | Employés | Création | Partiellement fonctionnel | `@PreAuthorize("hasRole('RH_MANAGER')")` `EmployeeController.java:98` : ADMIN, HR_ADMIN reçoivent 403 alors que l'UI leur ouvre l'écran | AN-09 |
| 11 | Employés | Modification | Partiellement fonctionnel | Même restriction ; poste/département/manager (FK) jamais mis à jour | AN-09, AN-17 |
| 12 | Employés | Archivage (désactive le compte) | Fonctionnel mais partiellement vérifié | `EmployeeService.archive` | Voir AN-07 (jeton reste valide) |
| 13 | Employés | Fiche détail : présences, congés, paie | Fonctionnel mais partiellement vérifié | `/employees/{m}/presences|conges|paie` appelés par `employee_detail_screen.dart` | Restreindre (AN-03) |
| 14 | Employés | Documents : ajout / téléchargement | Non implémenté | Boutons `onPressed: () {}` `employee_detail_screen.dart:524, 802, 810, 1029` ; aucun endpoint d'upload | AN-26 |
| 15 | Employés | Compétences | Partiellement fonctionnel | Lecture seule (`GET /{m}/competences`), aucune création/édition | Compléter si requis |
| 16 | Employés | Équipe du manager | Non fonctionnel | Frontend appelle `/employees/my-team` — endpoint inexistant | AN-10 |
| 17 | Organisation | CRUD départements | Fonctionnel mais partiellement vérifié | `DepartementService` ↔ `departement_provider.dart` | — |
| 18 | Organisation | Organigramme | Fonctionnel mais partiellement vérifié | `/departements/organigramme` ; vide en pratique faute de lien employé (AN-17) | AN-17 |
| 19 | Organisation | CRUD services | Fonctionnel mais partiellement vérifié | `ServiceController` ; services aussi créés implicitement par `findOrCreateService` | Éviter la création implicite (typos) |
| 20 | Organisation | CRUD postes | Fonctionnel mais partiellement vérifié | `PosteService` ↔ `poste_provider.dart` | — |
| 21 | Organisation | Affectation employé ↔ poste / département / manager | Non implémenté | `EmployeeRequest` ne contient ni `posteId`, ni `departementId`, ni `managerId` | AN-17 |
| 22 | Contrats | Historique des contrats par employé | Partiellement fonctionnel | API `GET /employees/{m}/contrats` présente, **aucun appel frontend** | AN-25 |
| 23 | Contrats | Création / changement de statut | Partiellement fonctionnel | API présente, **aucune UI** (`contrats_screen.dart` n'appelle que `/contrats/expirant`) | AN-25 |
| 24 | Contrats | Alerte contrats arrivant à échéance (30 j) | Fonctionnel mais partiellement vérifié | `contrats_screen.dart:17` | — |
| 25 | Recrutement | Offres : création, liste, statut | Fonctionnel mais partiellement vérifié | `RecrutementService` ↔ `recrutement_provider.dart` | — |
| 26 | Recrutement | Candidature publique (`/apply`) | Non fonctionnel | Route publique côté Flutter (`app_router.dart` : « pas d'auth requise ») mais `/api/offres/**` exige l'authentification (`SecurityConfig` : `anyRequest().authenticated()`) → 401 | AN-11 |
| 27 | Recrutement | Suivi des candidatures, statut, note | Fonctionnel mais partiellement vérifié | `updateStatutCandidature` ; statut en texte libre | AN-31 |
| 28 | Recrutement | Téléchargement de CV | Non fonctionnel | `recrutement_provider.dart:113` appelle `/api/candidatures/{id}/cv` alors que la base URL se termine déjà par `/api` → `/api/api/...` (404) | AN-12 |
| 29 | Recrutement | Planification d'entretiens | Fonctionnel mais partiellement vérifié | `POST /candidatures/{id}/entretiens` | — |
| 30 | Recrutement | Embauche → création employé | Partiellement fonctionnel | `RecrutementService.embaucher:145` : pas de contrôle de statut, ré-embauche possible (bloquée seulement par l'unicité e-mail), service « Non défini » créé automatiquement | AN-31 |
| 31 | Congés | Demande (écran Congés) | Fonctionnel mais partiellement vérifié | `CongeService.submit` ↔ `conge_provider.dart:73` | AN-14 |
| 32 | Congés | Demande depuis l'espace employé | Partiellement fonctionnel | Type « Exceptionnel » (`employee_workspace_screen.dart:1232`) inexistant dans `TypeConge` → 400 ; « Maternité » absent | AN-15 |
| 33 | Congés | Approbation / refus par les RH | Partiellement fonctionnel | Fonctionne techniquement, mais **aucun contrôle de rôle**, approbateur non enregistré | AN-01, AN-14 |
| 34 | Congés | Approbation / refus par le manager | Non fonctionnel | `manager_dashboard_screen.dart:335,354` : `PUT /conges/{id}/approuver|refuser` ; le backend expose `POST /conges/{id}/approve|reject` | AN-10 |
| 35 | Congés | Double validation manager → RH | Non implémenté | Colonnes `approbateur_id`, `validateur_id` (V23) et commentaire « EN_ATTENTE → APPROUVE_MANAGER → VALIDE » ; l'enum `StatutConge` n'a que 3 valeurs et le code n'utilise pas ces colonnes | AN-14 |
| 36 | Congés | Gestion du solde | Partiellement fonctionnel | Jours calendaires, solde initial fixe 30, pas d'acquisition mensuelle, pas de réservation des demandes en attente, pas de contrôle de chevauchement | AN-14 |
| 37 | Présences | Pointage mobile (GPS) | Partiellement fonctionnel | `PresenceService.pointage` : coordonnées client non contrôlées, heure d'arrivée écrasée à chaque « ENTREE » | AN-28 |
| 38 | Présences | Pointage par QR code | Partiellement fonctionnel | Jeton statique sans expiration ; tout utilisateur authentifié peut scanner le jeton d'un autre | AN-05, AN-28 |
| 39 | Présences | Déclaration d'absence (employé) | Fonctionnel mais partiellement vérifié | `reportAbsence` limité à l'employé courant | — |
| 40 | Présences | Justification d'absence | Partiellement fonctionnel | Aucun contrôle d'appartenance ; passe directement à `ABSENT_JUSTIFIEE` sans validation RH | AN-05 |
| 41 | Présences | Vue RH des présences | Partiellement fonctionnel | `findTop50ByOrderByDateDesc` : 50 lignes max, pas de filtre ni pagination | AN-29 |
| 42 | Présences | Horaires, retards, heures supplémentaires | Non implémenté | Aucun modèle d'horaire | Besoin métier à confirmer |
| 43 | Paie | Calcul mensuel | Partiellement fonctionnel | `PaieService.calculateAll` : CNSS 4 %, impôts 8 %, indemnités 5 % codés en dur ; ignore absences/sans solde/primes ; écrase les bulletins déjà validés | AN-02, AN-13 |
| 44 | Paie | Validation de la période | Fonctionnel mais partiellement vérifié | `validateForPeriod` (ADMIN, RH_MANAGER uniquement) | AN-09 |
| 45 | Paie | Bulletin PDF | Partiellement fonctionnel | PDF minimal sans mentions employeur ; accessible à tout utilisateur par ID | AN-02, AN-39 |
| 46 | Paie | Export CSV | Fonctionnel mais partiellement vérifié | `exportCsv` avec échappement CSV | — |
| 47 | Paie | Primes / indemnités / retenues variables | Non implémenté | Aucun modèle | Besoin métier à confirmer |
| 48 | Évaluations | Création, soumission, validation | Fonctionnel mais partiellement vérifié | `EvaluationService` ↔ `evaluation_provider.dart` | — |
| 49 | Évaluations | Objectifs | Partiellement fonctionnel | Lecture seule `/employees/me/objectifs`, aucune création | Compléter |
| 50 | Formations | Création, liste | Fonctionnel mais partiellement vérifié | `formation_provider.dart:23` | — |
| 51 | Formations | Inscription d'un employé | Fonctionnel mais partiellement vérifié | `formation_provider.dart:32` | — |
| 52 | Formations | Modification, suivi de participation | Partiellement fonctionnel | `PUT /formations/{id}` et `/participation/{m}` sans aucun appel frontend | Ajouter l'UI |
| 53 | Notifications | Liste, marquer lu, tout marquer lu | Fonctionnel mais partiellement vérifié | Contrôle d'appartenance correct `NotificationService.markRead:66` | — |
| 54 | Notifications | Événements déclencheurs | Partiellement fonctionnel | Notifie l'employé (décision congé, bulletin, scan) ; **aucune notification au valideur** lors d'une nouvelle demande | AN-14 |
| 55 | Notifications | Cloche du dashboard RH | Non fonctionnel | `rh_dashboard.dart:47` `onPressed: () {}` + badge statique « 3 » (écran par ailleurs non routé, cf. AN-36) | AN-30 |
| 56 | Dashboards | Dashboard RH (summary / enhanced) | Fonctionnel mais partiellement vérifié | `DashboardService` ↔ `rh_dashboard_modern.dart` | AN-34 |
| 57 | Dashboards | Dashboard Direction | Partiellement fonctionnel | Évolution de la masse salariale **fabriquée** (`DashboardService.buildPayrollEvolution` : base × 0,92…1,02) + valeurs fictives en repli (`direction_dashboard.dart:276`) | AN-16 |
| 58 | Dashboards | Console Admin | Partiellement fonctionnel | Sections statiques : congés, anniversaires, composition paie « 25 780 000 FCFA », courbe (`admin_console_screen.dart:494-502, 746-750, 877, 1218, 1327`) | AN-16 |
| 59 | Dashboards | Dashboard Manager | Non fonctionnel | Dépend de `/employees/my-team` (inexistant) et de `PUT …/approuver` (inexistant) ; le filtre `?statut=` est ignoré | AN-10 |
| 60 | Dashboards | Espace employé | Fonctionnel mais partiellement vérifié | Utilise `/me` (employé, congés, présences, documents, objectifs, évaluations, QR) | AN-15 |
| 61 | Rapports | Export synthèse PDF / Excel | Fonctionnel mais partiellement vérifié | `ReportController#export` — **aucune restriction de rôle** | AN-04 |
| 62 | Rapports | Rapports personnalisés (présences, congés, paie, effectifs) | Fonctionnel mais partiellement vérifié | `ReportService.generateReport` (ADMIN, RH_MANAGER, DIRECTION) | AN-09 |
| 63 | Audit | Journal d'audit | Partiellement fonctionnel | Seules 2 actions annotées `@Auditable` (création / modification employé) | AN-24 |
| 64 | Profil | Photo de profil | Fonctionnel mais partiellement vérifié | `ProfileController#uploadPhoto` | AN-20 |
| 65 | Plateforme | Multi-entreprises / isolation des PME | Non implémenté | §A.6 | AN-18 |
| 66 | RH | Sanctions / procédures disciplinaires | Non implémenté | Aucun code | Besoin à confirmer |
| 67 | RH | Carrières / promotions | Non implémenté | Aucun code | Besoin à confirmer |
| 68 | Données | Import de données (employés, etc.) | Non implémenté | Aucun code | Besoin à confirmer |

**Synthèse** : 68 fonctionnalités — 0 fonctionnel et vérifié, 27 fonctionnel mais partiellement vérifié, 22 partiellement fonctionnel, 8 non fonctionnel, 11 non implémenté.

---

## D. LISTE DES ANOMALIES

Récapitulatif : **6 critiques, 12 élevées, 17 moyennes, 5 faibles (40 au total).**

### D.1 Anomalies CRITIQUES

#### AN-01 — Congés : approbation, refus et consultation sans contrôle d'accès
- **Module / fonctionnalité** : Congés / validation.
- **Description** : `POST /api/conges/{id}/approve`, `/reject` et `GET /api/conges` n'ont pas de `@PreAuthorize` (`CongeController.java:30-56`) et `CongeService.approve/reject/listAll` ne vérifient ni rôle ni hiérarchie.
- **Comportement actuel** : tout utilisateur authentifié (y compris EMPLOYEE) peut approuver **sa propre demande** ou celle de n'importe qui, et lire toutes les demandes (motifs, congés maladie) de l'entreprise.
- **Attendu** : seuls le manager de l'employé et/ou les RH peuvent décider ; un employé ne voit que ses demandes.
- **Cause** : sécurité uniquement assurée par le masquage des écrans côté Flutter.
- **Fichiers** : `controller/CongeController.java`, `service/CongeService.java`.
- **Conséquences** : fraude aux congés, décrément arbitraire de soldes, exposition de données de santé.
- **Solution** : `@PreAuthorize` RH/Manager sur approve/reject/list ; vérifier que le manager est bien `employe.manager` ; interdire l'auto-approbation ; enregistrer `approbateur` et `dateApprobation`.
- **Tests** : tests d'intégration MockMvc par rôle (EMPLOYEE → 403, MANAGER d'une autre équipe → 403, RH → 204), test d'auto-approbation refusée.

#### AN-02 — Paie : calcul, consultation des salaires et bulletins accessibles à tous
- **Description** : `GET /api/paie?month&year`, `POST /api/paie/calculate`, `GET /api/paie/{id}/bulletin/pdf` sans restriction (`PaieController.java:32-53`). `generatePayslipPdf` ne vérifie pas le propriétaire.
- **Actuel** : un employé peut lister le salaire de tous ses collègues, déclencher un recalcul de toute la paie (y compris d'une période validée, cf. AN-13) et télécharger n'importe quel bulletin en incrémentant l'ID (IDOR).
- **Attendu** : calcul réservé aux RH/paie ; consultation limitée à ses propres bulletins pour l'employé.
- **Fichiers** : `controller/PaieController.java`, `service/PaieService.java`.
- **Conséquences** : violation de la confidentialité salariale, altération de données de paie.
- **Solution** : `@PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','PAYROLL_OFFICER')")` sur list/calculate ; contrôle propriétaire-ou-RH sur le bulletin ; endpoint `/paie/me`.
- **Tests** : matrice rôle × endpoint ; test IDOR sur bulletin d'un autre employé → 403/404.

#### AN-03 — Dossiers du personnel exposés à tout utilisateur authentifié (IDOR)
- **Description** : `GET /api/employees` (liste paginée **avec le salaire** — `EmployeeResponse.salaire`), `GET /api/employees/{matricule}`, `/{m}/paie`, `/{m}/documents`, `/{m}/presences`, `/{m}/conges`, `/{m}/competences`, `/{m}/contrats` ne portent aucun contrôle (`EmployeeController.java:80-143`, `ContratController.java:25`).
- **Actuel** : un employé connaît les matricules (affichés dans la liste) et peut lire l'intégralité des dossiers et salaires.
- **Attendu** : RH = tout ; manager = son équipe, sans salaire sauf décision métier ; employé = soi-même.
- **Solution** : `@PreAuthorize` + service d'autorisation `canAccessEmployee(matricule)` ; DTO distinct sans données salariales pour les profils non RH.
- **Tests** : tests d'autorisation par rôle et par lien hiérarchique.

#### AN-04 — Rapport de synthèse et export Excel de paie accessibles à tous
- **Description** : `GET /api/reports/export?format=excel` (`ReportController.java:29`) n'a pas de `@PreAuthorize` ; l'Excel contient la feuille « Paie » de tous les employés du mois (`ReportService.exportExcel`).
- **Conséquences** : fuite massive de données salariales en un appel.
- **Solution** : restreindre à ADMIN / HR_ADMIN / RH_MANAGER / DIRECTION (à confirmer).
- **Tests** : EMPLOYEE → 403.

#### AN-05 — Présences : justification d'absence d'autrui, scan QR frauduleux, liste globale
- **Description** :
  - `PUT /api/presences/{id}/justify` : aucune vérification que la présence appartient à l'appelant, ni validation RH ; le statut passe directement à `ABSENT_JUSTIFIEE` (`PresenceService.justifyAbsence`).
  - `POST /api/presences/scan` : accessible à tout authentifié ; quiconque possède (photo/capture) le jeton QR statique d'un collègue peut pointer pour lui (`PresenceService.scanPointage`, `QrCodeService` — jeton UUID sans expiration).
  - `GET /api/presences` : présences de tous (avec coordonnées GPS) visibles par tous.
- **Conséquences** : falsification du temps de présence, absences injustifiées blanchies, atteinte à la vie privée (géolocalisation).
- **Solution** : rôle « borne/agent de pointage » ou RH pour `/scan` ; QR dynamique (jeton signé à durée courte, type TOTP) ; contrôle propriétaire et statut intermédiaire « JUSTIFICATIF_SOUMIS » validé par RH ; restreindre la liste.
- **Tests** : tests d'autorisation ; test de rejeu d'un QR expiré.

#### AN-06 — Secrets et identifiants par défaut
- **Description** (`application.yml`, `DataSeeder.java`, `EmployeeService.java:93`, `AdminController.java:74`) :
  - `JWT_SECRET` par défaut public (`change-me-…`) : si la variable n'est pas définie, **n'importe qui peut forger un jeton SUPER_ADMIN** ;
  - administrateur amorcé `admin@grh-mobile.com / Admin@12345`, `BOOTSTRAP_ADMIN_RESET_PASSWORD` **true par défaut** : le mot de passe admin est réinitialisé à chaque démarrage ;
  - tout employé créé (et tout compte de démo) reçoit `ChangeMe@123`, sans changement forcé au premier login ;
  - mot de passe BDD par défaut `grhpassword`.
- **Solution** : supprimer les valeurs par défaut sensibles (échec au démarrage si absentes), `reset-password-on-startup=false`, mot de passe initial aléatoire transmis hors bande + changement obligatoire, désactiver le seeder hors profil dev.
- **Tests** : démarrage sans `JWT_SECRET` → échec ; test du flag « doit changer son mot de passe ».

### D.2 Anomalies ÉLEVÉES

| ID | Module | Description / comportement actuel | Attendu | Cause / fichiers | Conséquences | Solution | Tests |
|---|---|---|---|---|---|---|---|
| AN-07 | Sécurité / session | Un compte désactivé ou archivé garde l'accès jusqu'à expiration du JWT (8 h) : le filtre ne vérifie que le nom et l'expiration. | Accès coupé immédiatement. | `JwtAuthenticationFilter`, `JwtService.isTokenValid` n'appellent pas `isEnabled()` | Ex-salarié conservant l'accès aux données RH | Vérifier `userPrincipal.isEnabled()` dans le filtre ; réduire la durée ; refresh token | Désactiver un compte puis rappeler l'API → 401 |
| AN-08 | Utilisateurs / rôles | Un ADMIN peut créer ou promouvoir un SUPER_ADMIN ; `Role.valueOf` sans contrôle (500/400 bruts) ; mot de passe par défaut si vide. À l'inverse, SUPER_ADMIN reçoit 403 sur `/api/admin/**` (pas de `RoleHierarchy`) alors que le frontend lui ouvre ces écrans. | Hiérarchie de rôles explicite ; seul SUPER_ADMIN gère les SUPER_ADMIN. | `AdminController`, `SecurityConfig` | Escalade de privilèges ; SUPER_ADMIN inopérant | `RoleHierarchy` ; DTO validés ; règles d'attribution des rôles | Tests par rôle sur `/api/admin/**` |
| AN-09 | Transverse | Incohérence des droits front/back : l'UI ouvre `/rh/*` à HR_ADMIN et l'admin, mais `POST/PUT /employees` exigent **uniquement** RH_MANAGER ; validation/export paie limités à ADMIN/RH_MANAGER (HR_ADMIN et PAYROLL_OFFICER exclus alors que l'écran Paie est leur accueil) ; rapports personnalisés excluent HR_ADMIN. | Une matrice de droits unique, identique côté client et serveur. | `@PreAuthorize` dispersés ; `app_router.dart:40-87` | Utilisateurs bloqués par des 403 inexpliqués | Centraliser la matrice (constantes ou permissions effectivement appliquées) | Tests de bout en bout par rôle |
| AN-10 | Manager | Le dashboard manager appelle `/employees/my-team` (inexistant) et `PUT /conges/{id}/approuver|refuser` (le backend expose `POST …/approve|reject`). `GET /conges?statut=EN_ATTENTE` ignore le paramètre et renvoie tout. | Le manager voit son équipe et traite ses demandes. | `manager_dashboard_screen.dart:23, 335, 354` | Rôle Manager inutilisable | Créer `/employees/my-team` (basé sur `manager_id`), corriger verbe et URL, filtrer par équipe | Test widget + test API |
| AN-11 | Recrutement | La page publique `/apply` ne peut pas fonctionner : toutes les routes `/api/offres/**` exigent un JWT. | Candidature externe sans compte. | `SecurityConfig.java:48-52` vs `app_router.dart` | Recrutement externe impossible | Endpoints publics dédiés (lecture des offres publiées, dépôt de candidature) avec limitation de débit et contrôle des fichiers | Test anonyme → 201 ; anonyme sur endpoints RH → 401 |
| AN-12 | Recrutement | Téléchargement de CV : URL `/api/candidatures/{id}/cv` + base `…/api` → `/api/api/…` (404). | Téléchargement du CV. | `recrutement_provider.dart:113` | CV inaccessibles aux recruteurs | Retirer le préfixe `/api` | Test manuel + test unitaire de l'URL |
| AN-13 | Paie | Calcul forfaitaire : CNSS 4 %, impôts 8 %, « indemnités » +5 % du brut pour tous ; aucune prise en compte des absences, congés sans solde, heures sup, primes, barème fiscal, part patronale. Le recalcul **écrase les fiches déjà validées** et renvoie une notification à chaque exécution. | Règles de paie conformes à la législation applicable, verrouillage après validation. | `PaieService.calculateAll` | Bulletins erronés, risque légal | Verrouiller les fiches `validee` ; externaliser les taux en paramètres datés ; **faire valider les règles par un expert paie** | Tests unitaires de calcul avec cas de référence fournis par le métier |
| AN-14 | Congés | Workflow incomplet : double validation prévue (V23) non codée ; approbateur/date non enregistrés ; aucune notification au valideur à la soumission ; pas de contrôle de chevauchement ; comptage en jours calendaires (week-ends et fériés inclus) ; solde non réservé pour les demandes en attente (plusieurs demandes peuvent dépasser le solde) ; dates passées acceptées. | Workflow défini par le métier. | `CongeService`, `StatutConge`, `V23__improve_conge_workflow.sql` | Soldes faux, demandes non vues | Implémenter le workflow cible après confirmation des règles | Tests de service sur chaque transition |
| AN-15 | Congés | L'espace employé propose « Exceptionnel » (absent de `TypeConge` → 400 avec message technique « No enum constant… ») et n'offre pas « Maternité ». Les deux écrans de demande divergent. | Liste unique de types, issue du backend. | `employee_workspace_screen.dart:1229-1240`, `TypeConge.java` | Demandes impossibles | Endpoint de référentiel ou alignement des listes ; gestion propre de l'erreur | Test par type |
| AN-16 | Dashboards | Données fictives présentées comme réelles : console admin (congés, anniversaires, composition paie 25 780 000 FCFA, courbe annuelle) ; dashboard direction (courbe masse salariale calculée synthétiquement côté serveur + valeurs inventées en repli). | Données réelles ou état vide explicite. | `admin_console_screen.dart:494-502, 746-750, 877, 1218-1331` ; `DashboardService.buildPayrollEvolution` ; `direction_dashboard.dart:276-284` | Décisions de direction prises sur de faux chiffres | Brancher sur les vraies données (historique `fiches_paie`) ou afficher « aucune donnée » | Test avec base vide → aucun chiffre inventé |
| AN-17 | Organisation | Les FK employé → poste, département, manager (V18) ne sont jamais alimentées : `EmployeeRequest` n'a pas ces champs, `applyRequest` ne les traite pas. Les employés utilisent encore les champs texte `poste` et `service`. | Employé rattaché au référentiel. | `EmployeeService.applyRequest`, `EmployeeRequest` | Organigramme vide, équipes manager vides, effectifs par département faux | Ajouter `posteId`, `departementId`, `managerId` ; migrer les données texte | Tests de création/édition + organigramme |
| AN-18 | Plateforme | Aucune isolation multi-entreprise alors que le projet se présente comme SaaS et déclare un SUPER_ADMIN « multi-entreprise ». | Selon le modèle cible (à confirmer). | Absence d'entité Entreprise | Mélange de données entre PME si mutualisé | Décision d'architecture : une instance par PME ou `entreprise_id` + filtre systématique | Tests d'isolation inter-entreprises |

### D.3 Anomalies MOYENNES

| ID | Module | Description | Fichiers | Solution recommandée | Tests |
|---|---|---|---|---|---|
| AN-19 | Sécurité | Les erreurs 500 renvoient `exception.getMessage()` au client ; les `IllegalArgumentException` d'enum exposent les noms de classes Java. | `ApiExceptionHandler.java:55-57`, `CongeService.parseTypeConge`, `AdminController` | Message générique + identifiant de corrélation, détail en logs uniquement | Test d'une erreur forcée |
| AN-20 | Sécurité | Photos de profil publiques (`/uploads/photos/**` en `permitAll`), nom prévisible `{userId}.jpg`, type vérifié via l'en-tête `Content-Type` seulement. | `ProfileController.java:44-100`, `SecurityConfig.java:50` | Nom aléatoire, vérification des octets magiques, accès authentifié | Upload d'un faux JPEG → rejet |
| AN-21 | Sécurité / données | Pièce jointe de justification transmise en base64 dans le JSON et stockée en BDD, sans contrôle de type ni de taille. | `PresenceService.justifyAbsence`, `JustifyAbsenceRequest` | Upload multipart avec limites, stockage fichier | Test de taille maximale |
| AN-22 | Sécurité | `httpBasic()` activé en plus du JWT ; aucune limitation des tentatives de connexion. | `SecurityConfig.java:43` | Désactiver httpBasic ; limitation par IP/compte, verrouillage temporaire | Test de N échecs → blocage |
| AN-23 | Sécurité | Le fichier `.env` est déclaré comme asset Flutter (`pubspec.yaml`) : il est embarqué en clair dans l'APK/IPA/bundle web. Aujourd'hui il ne contient que l'URL, les empreintes de certificat et le délai d'inactivité, mais tout secret ajouté plus tard serait publié. Note : les dossiers `build/` présents dans Git en contiennent des copies. | `pubspec.yaml`, `.gitignore` | `--dart-define` pour la configuration ; ne jamais y mettre de secrets ; ignorer `build/` | Inspection du bundle |
| AN-24 | Traçabilité | Seules la création et la modification d'employé sont auditées. Aucune trace pour : connexions, changements de rôle, paie (calcul, validation, export), congés (décisions), consultations de dossiers, suppressions. | `AuditAspect`, `@Auditable` (2 usages dans `EmployeeService`) | Annoter les actions sensibles ; journaliser les accès aux données salariales | Vérifier une entrée d'audit par action |
| AN-25 | Contrats | Création de contrat, changement de statut et historique par employé exposés par l'API sans aucune interface. | `ContratController`, `contrats_screen.dart` | Ajouter l'UI dans la fiche employé | Tests widget + API |
| AN-26 | Employés | « Ajouter un document », « Télécharger », menu « ⋮ » sans action ; aucun endpoint d'upload ou de téléchargement de document. | `employee_detail_screen.dart:524, 802, 810, 1029` | Implémenter (stockage, droits) ou masquer les boutons | Tests d'upload / téléchargement / droits |
| AN-27 | Admin | Écran « Rôles & permissions » et « Paramètres » : les modifications sont enregistrées mais **n'ont aucun effet** (aucune lecture côté sécurité ou métier). Fonctionnalité simulée. | `PermissionController`, `AdminController#settings`, `admin_roles_screen.dart`, `admin_settings_screen.dart` | Soit appliquer réellement les permissions, soit retirer ou étiqueter ces écrans | Changer une permission → effet observable |
| AN-28 | Présences | `pointage` : chaque « ENTREE » écrase l'heure d'arrivée ; pas de contrôle d'ordre (SORTIE sans ENTREE) ; coordonnées GPS déclarées par le client sans géorepérage ; QR statique. | `PresenceService.pointage`, `QrCodeService` | Règles d'ordre, zone autorisée (à confirmer), QR à durée courte | Tests de séquence de pointage |
| AN-29 | Présences / congés | Vue RH limitée aux 50 dernières présences ; aucun filtre (date, service, employé) ; `GET /conges` ignore `?statut`. | `PresenceService.listAll`, `CongeController.list` | Pagination + filtres côté serveur | Tests de filtres |
| AN-30 | UX / boutons morts | « Mot de passe oublié » (`login_screen.dart:123`) et cloche notifications (`rh_dashboard.dart:47`, badge « 3 » statique) sans action. | — | Implémenter ou retirer | Revue visuelle |
| AN-31 | Recrutement | Embauche sans contrôle de statut ni protection contre la ré-embauche ; statut de candidature en texte libre (aucune énumération) ; création implicite du service « Non défini ». | `RecrutementService.embaucher`, `updateStatutCandidature` | Enum de statuts + transitions autorisées ; refuser l'embauche d'un candidat déjà retenu | Tests de transitions |
| AN-32 | Données | Matricule généré à partir de `employeRepository.count() + 1` : collision possible en création concurrente (rejet 409 grâce à la contrainte d'unicité). | `EmployeeService.generateMatricule` | Séquence BDD | Test de création concurrente |
| AN-33 | Qualité | Couverture de tests quasi nulle : backend = 1 test `contextLoads` (nécessite PostgreSQL) ; frontend = 4 fichiers (formatters, validators, modèles, widget de base). Aucun test de sécurité ni de règle métier. | `backend/src/test`, `test/` | Tests de service + MockMvc + Testcontainers ; tests widget des écrans clés | — |
| AN-34 | Performance | `findAll()` chargés en mémoire (dashboard, `AdminController#stats` appelle deux fois `employeRepository.findAll()`, `CongeService.listAll`, liste des utilisateurs) ; une requête par employé dans `EmployeeService.toResponse` (N+1) ; relations LAZY parcourues hors requêtes dédiées. | `DashboardService`, `AdminController`, `EmployeeService` | Requêtes d'agrégation (`count`, `sum`), projections, fetch join | Test de charge simple |
| AN-35 | Indicateurs | Turnover = archivés (depuis toujours) / total historique, sans période ; masse salariale = somme des salaires de base de **tous** les employés, archivés compris. | `DashboardService.getSummary` | Définir les formules avec le métier (période, effectif moyen) ; filtrer les actifs | Tests unitaires de formules |

### D.4 Anomalies FAIBLES

| ID | Description | Fichiers | Solution |
|---|---|---|---|
| AN-36 | Code mort et fichiers parasites : `rh_dashboard.dart` (non routé, remplacé par `rh_dashboard_modern.dart`) ; dossier `android_backup/` ; logs de crash à la racine (`hs_err_pid35520.log`, `replay_pid35520.log`, `flutter-emulator.*.log`) ; dossier `build/` suivi par Git (le `.gitignore` ignore `.build/` au lieu de `build/`) ; `backend/uploads/cv` et `uploads/cv` en double. | racine, `.gitignore` | Nettoyage après validation |
| AN-37 | Écrans monolithiques difficiles à maintenir : `employee_workspace_screen.dart` (3 808 lignes), `admin_console_screen.dart` (2 299), `employee_list_screen.dart` (1 542). | `lib/features/…` | Découper en widgets et providers |
| AN-38 | Trou dans la numérotation des migrations (V6 → V10). Sans impact technique pour Flyway, mais à documenter (migrations perdues ?). | `db/migration` | Vérifier l'historique `flyway_schema_history` en production |
| AN-39 | Bulletin PDF rudimentaire : pas d'identité de l'employeur, pas de matricule, montants non formatés, champ « Poste » texte libre. Mentions légales obligatoires **à confirmer** avec le métier. | `PaieService.generatePayslipPdf` | Modèle de bulletin validé par le métier |
| AN-40 | Pas d'intégration continue (`.github/` sans workflow) : aucune vérification automatique de compilation, d'analyse ou de tests. | `.github/` | Pipeline : `mvn verify`, `flutter analyze`, `flutter test` |

---

## E. ANALYSE DE SÉCURITÉ

### E.1 Synthèse

| Contrôle | Constat | Statut |
|---|---|---|
| Stockage des mots de passe | BCrypt (`SecurityConfig.passwordEncoder`) | ✅ Conforme |
| Authentification | JWT HS256 signé, stateless | ⚠️ Secret par défaut (AN-06), pas de révocation (AN-07), httpBasic parallèle (AN-22) |
| Autorisation par rôle | `@PreAuthorize` présent sur environ la moitié des endpoints d'écriture ; **absent sur les lectures sensibles et plusieurs écritures** | ❌ Critique (AN-01 à AN-05) |
| Contrôle d'appartenance (IDOR) | Seul `NotificationService.markRead` vérifie le propriétaire | ❌ Critique |
| Données salariales | Exposées via `/employees`, `/paie`, `/reports/export` | ❌ Critique |
| Documents confidentiels | CV : accès RH uniquement ✅ ; chemin de fichier absolu stocké en BDD ; photos publiques ⚠️ | ⚠️ |
| Injection SQL | Spring Data JPA, requêtes paramétrées (`EmployeRepository.search` avec paramètres) ; aucune concaténation SQL trouvée | ✅ Pas de risque identifié |
| XSS | Client Flutter natif (pas de rendu HTML) ; risque faible. Version web : à vérifier | ✅ / [NV] |
| CSRF | Désactivé — acceptable pour une API stateless par jeton Bearer ; mais `allowCredentials(true)` + httpBasic actif à réévaluer | ⚠️ |
| CORS | Liste d'origines `localhost` par défaut, configurable | ✅ |
| Secrets dans le code | Valeurs par défaut dans `application.yml` / `.env.example` ; `.env` racine non suivi par Git ✅ mais embarqué dans l'app (AN-23) | ⚠️ |
| Journalisation des actions sensibles | Très partielle (AN-24) | ❌ |
| Transport | Épinglage de certificat optionnel côté mobile | ✅ (à activer en production) |
| Actuator | `health`/`info` publics ; `metrics`/`prometheus` exposés mais authentifiés — à restreindre à un rôle technique | ⚠️ |
| Isolation multi-entreprise | Inexistante (AN-18) | ❌ si SaaS mutualisé |

### E.2 Matrice d'exposition (constatée dans le code, endpoints sans restriction de rôle)

| Endpoint | Donnée / action | Accessible à |
|---|---|---|
| `GET /api/employees`, `/{m}` | Identité, contact, **salaire** | Tout authentifié |
| `GET /api/employees/{m}/paie`, `/documents`, `/presences`, `/conges`, `/competences`, `/contrats` | Dossier complet | Tout authentifié |
| `GET /api/paie?month&year` | Salaires de tous | Tout authentifié |
| `POST /api/paie/calculate` | Recalcul de la paie | Tout authentifié |
| `GET /api/paie/{id}/bulletin/pdf` | Bulletin d'autrui | Tout authentifié |
| `GET /api/reports/export` | Synthèse + paie (Excel) | Tout authentifié |
| `GET /api/conges`, `POST /{id}/approve|reject` | Congés de tous / décision | Tout authentifié |
| `GET /api/presences`, `PUT /{id}/justify`, `POST /scan` | Présences + GPS / justification / pointage | Tout authentifié |
| `GET /api/dashboard/summary|enhanced` | Masse salariale, KPI | Tout authentifié |
| `GET /api/departements`, `/postes`, `/services`, `/services/{id}/employes`, `/offres`, `/formations` | Référentiels (faible sensibilité) | Tout authentifié |

> Ces constats proviennent de la lecture du code. **Aucun test d'intrusion n'a été exécuté** (pas d'environnement, et aucune opération sur données réelles conformément aux consignes).

### E.3 Mesures recommandées (par ordre)

1. Imposer `JWT_SECRET` et le mot de passe admin par variables obligatoires ; désactiver la réinitialisation au démarrage.
2. Ajouter les `@PreAuthorize` manquants et un service d'autorisation par ressource (propriétaire / manager / RH).
3. Vérifier `isEnabled()` dans le filtre JWT ; réduire la durée du jeton.
4. Introduire une `RoleHierarchy` et une matrice de droits unique partagée entre backend et frontend.
5. Séparer les DTO « RH » (avec salaire) des DTO « annuaire ».
6. Étendre l'audit aux actions sensibles, y compris les consultations de données salariales.
7. Limiter les tentatives de connexion ; désactiver httpBasic.
8. Durcir les uploads (type réel, taille, nom aléatoire, accès authentifié).

---

## F. ANALYSE UX/UI

> Analyse **sur le code uniquement** ; l'interface n'a pas pu être affichée. Les points ci-dessous sont à confirmer visuellement.

**Points positifs [CODE]**
- Système de design centralisé (`app_colors.dart`, `app_theme.dart`, widgets partagés : `GrhSurfaceCard`, `KpiCard`, `StatusBadge`, `ConfirmDialog`, `LoadingOverlay`).
- Mise en page adaptative : barre latérale à partir de 1024 px, tiroir et barre de navigation inférieure sur mobile (`isWide` dans les écrans).
- Dialogues de confirmation et snackbars présents sur les actions destructrices et les soumissions.
- États de chargement via `AsyncValue` (Riverpod) dans la plupart des écrans.

**Problèmes identifiés**

| # | Problème | Exemple | Amélioration proposée |
|---|---|---|---|
| UX-1 | Boutons visibles mais inactifs | Documents employé, mot de passe oublié, cloche RH (AN-26, AN-30) | Masquer ou désactiver avec info-bulle « bientôt disponible » |
| UX-2 | Chiffres fictifs indiscernables des vrais | Console admin, dashboard direction (AN-16) | États vides explicites (« Aucune donnée pour la période ») |
| UX-3 | Erreurs 403 / 404 silencieuses ou brutes | Rôles HR_ADMIN / PAYROLL_OFFICER bloqués (AN-09) ; message « No enum constant… » (AN-15) | Traduction systématique des codes HTTP en messages métier |
| UX-4 | Deux formulaires de congé différents | `conge_request_screen.dart` vs espace employé | Un seul composant de demande réutilisé |
| UX-5 | Écran Contrats limité aux échéances | Pas de création ni d'historique (AN-25) | Onglet « Contrats » dans la fiche employé |
| UX-6 | Listes non paginées / non filtrables | Présences (50 lignes), congés | Filtres période / service / statut + pagination |
| UX-7 | Saisie du poste et du service en texte libre | Formulaire employé | Listes déroulantes alimentées par les référentiels |
| UX-8 | Accessibilité non traitée | Pas de `Semantics` repéré, petites tailles de police (11 px) dans les listes | Revue d'accessibilité (contraste, tailles, lecteurs d'écran) |
| UX-9 | Écrans très longs | Espace employé de 3 800 lignes regroupant de nombreux onglets | Découpage, navigation plus lisible |

---

## G. AMÉLIORATIONS FONCTIONNELLES (facultatives — hors corrections)

Ces propositions **ne sont pas des exigences** : elles sont à arbitrer avec le métier.

1. **Congés** : calendrier d'équipe, prise en compte des jours fériés paramétrables, acquisition mensuelle automatique du solde, report N-1 (règles à confirmer selon la législation et la convention applicables).
2. **Présences** : horaires de référence par service, calcul des retards et des heures supplémentaires, rapprochement automatique présences ↔ congés approuvés.
3. **Paie** : paramétrage des taux et barèmes par période, rubriques de primes/retenues, intégration des absences et congés sans solde, verrouillage et historique des versions.
4. **Contrats** : alertes automatiques (tâche planifiée) avant échéance et fin de période d'essai, génération de documents.
5. **Recrutement** : page carrière publique, pipeline visuel (kanban), conversion candidature → employé avec pré-remplissage complet.
6. **Dossier du personnel** : coffre-fort documentaire avec dates d'expiration (pièces d'identité, certificats).
7. **Tableaux de bord** : indicateurs calculés sur l'historique réel (absentéisme mensuel, turnover sur 12 mois glissants, pyramide des âges, répartition par sexe).
8. **Traçabilité** : écran d'historique par employé (qui a modifié quoi).
9. **Productivité** : import CSV/Excel des employés, actions groupées (validation en masse des congés).
10. **Notifications** : rappels automatiques aux valideurs, notifications push mobiles.

---

## H. PLAN DE CORRECTION

| Étape | Contenu | Anomalies |
|---|---|---|
| **1. Corrections critiques** | Secrets / identifiants par défaut ; contrôle d'accès sur congés, paie, employés, rapports, présences ; contrôle d'appartenance (IDOR) | AN-06, AN-01, AN-02, AN-03, AN-04, AN-05 |
| **2. Corrections prioritaires** | Jeton des comptes désactivés ; hiérarchie des rôles et escalade ; matrice de droits front/back unifiée ; verrouillage des fiches de paie validées ; décision multi-entreprise | AN-07, AN-08, AN-09, AN-13 (verrouillage), AN-18 (décision) |
| **3. Corrections fonctionnelles** | Dashboard manager et endpoint équipe ; candidature publique ; URL CV ; types de congé ; liaison employé ↔ poste / département / manager ; workflow congés ; suppression des données fictives ; contrats (UI) ; documents ; permissions et paramètres ; pointage ; embauche | AN-10, AN-11, AN-12, AN-15, AN-17, AN-14, AN-16, AN-25, AN-26, AN-27, AN-28, AN-31, AN-13 (règles, après validation métier) |
| **4. Améliorations techniques** | Gestion des erreurs ; uploads ; httpBasic et limitation des tentatives ; configuration Flutter ; audit ; matricule ; performances ; formules KPI ; tests ; CI | AN-19 à AN-24, AN-32 à AN-35, AN-33, AN-40 |
| **5. Améliorations UX/UI** | Boutons morts, états vides, filtres et pagination, unification des formulaires, accessibilité | AN-29, AN-30, UX-1 à UX-9 |
| **6. Optimisations complémentaires** | Nettoyage du dépôt, découpage des écrans, bulletin PDF, documentation des migrations, améliorations du §G | AN-36 à AN-39, §G |

---

## I. STRATÉGIE DE TESTS

### I.1 Vérifications réellement exécutées pendant cet audit

| Vérification | Commande | Résultat |
|---|---|---|
| Compilation backend (sources + tests) | `mvn -o test-compile` (heap 384 Mo) | ✅ **Succès** [BUILD] |
| Tests backend | `mvn -o test` | ❌ **Non exécutable** : la JVM n'a pas pu allouer sa mémoire (« fichier de pagination insuffisant »). De plus, le seul test (`contextLoads`) exige une base PostgreSQL non disponible. Ce crash a créé un fichier `backend/hs_err_pid37876.log`. |
| Analyse statique Flutter | `flutter analyze` | ⚠️ **0 erreur**, 27 avertissements, 207 infos (234 au total) [AUTO] — voir §I.4 |
| Tests Flutter | `flutter test` | ✅ **36/36 tests réussis** [AUTO] — mais ils ne couvrent que les formateurs, validateurs, modèles et un test fictif ; aucun écran ni flux métier |
| Tests manuels / visuels | — | ❌ Non réalisés (application non lancée : pas de BDD, mémoire insuffisante) |
| Tests de permissions / workflows / API | — | ❌ Non réalisés ; constats issus de la lecture du code |

### I.2 Tests à mettre en place après chaque catégorie de correction

| Catégorie | Tests requis |
|---|---|
| 1. Critiques | Tests d'intégration MockMvc (ou Testcontainers PostgreSQL) **pour chaque endpoint × chaque rôle** (matrice d'autorisation) ; tests IDOR (accès à la ressource d'un autre employé) ; démarrage sans `JWT_SECRET` → échec |
| 2. Prioritaires | Compte désactivé → 401 immédiat ; tests de hiérarchie des rôles ; recalcul d'une période validée → refus |
| 3. Fonctionnelles | Tests de service par règle métier (transitions de congé, solde, chevauchement, embauche, pointage) ; tests widget des écrans manager, congés et candidature ; un test de bout en bout par parcours (demande → validation → notification → solde) |
| 4. Techniques | Tests du gestionnaire d'erreurs (aucune fuite de message), tests d'upload (type/taille), test de création concurrente de matricules, tests unitaires des formules KPI, pipeline CI |
| 5. UX/UI | Revue visuelle par rôle sur mobile / tablette / desktop ; tests golden des écrans clés ; vérification des états vides et d'erreur |
| Non-régression | Rejouer l'ensemble de la suite à chaque lot ; `flutter analyze` sans erreur ; `mvn verify` vert |

### I.3 Limites de l'audit

- Aucune exécution de l'application : tous les statuts « fonctionnels » reposent sur la cohérence du code, pas sur une observation.
- Aucune base de données : schéma déduit des migrations Flyway, non comparé à une base réelle (validation `ddl-auto: validate` non exécutée).
- Ressources machine insuffisantes (crashs mémoire Dart VM et JVM) : tests automatisés non exécutés.
- Les règles métier de paie, de congés et les mentions légales **n'ont pas été évaluées au regard de la législation** : elles nécessitent une confirmation par un expert RH / paie.
- Les dépendances n'ont pas été passées dans un scanner de vulnérabilités (`mvn dependency-check`, `flutter pub outdated`) faute d'accès réseau garanti.
- L'audit porte sur l'état du répertoire de travail, qui contient des modifications non commitées (audit, employés, gestion d'erreurs côté backend ; providers et écrans côté frontend).

### I.4 Résultats Flutter

- `flutter analyze` (premier essai : crash « Out of memory » de la Dart VM ; deuxième essai réussi) : **aucune erreur de compilation**. Les 27 avertissements : 9 imports inutilisés, 5 champs inutilisés, 4 éléments inutilisés, 4 expressions `??` mortes (`paie_provider.dart:25-27`), 1 import dupliqué et 1 cast inutile (`admin_provider.dart:3, 45`), 1 usage d'un membre `@visibleForTesting`, 1 variable locale et 1 paramètre inutilisés. Les 207 infos sont majoritairement des API dépréciées (`withOpacity`) et des `const` manquants.
- `flutter test` : 36 tests réussis (`formatters_test`, `models_test`, `validators_test`, `widget_test` = test fictif).

---

## J. BILAN GÉNÉRAL

**Appréciation** : le projet est un **prototype avancé, riche fonctionnellement, mais non déployable en production en l'état**, principalement pour des raisons de sécurité.

**Points forts**
- Couverture fonctionnelle large (15 modules) et cohérente avec un SIRH de PME.
- Architecture claire et classique (contrôleur / service / dépôt ; Riverpod / go_router), facile à faire évoluer.
- Bonnes bases techniques : BCrypt, JWT, migrations Flyway versionnées, contraintes d'unicité, transactions sur les écritures, validation Bean Validation des DTO, échappement CSV, épinglage de certificat, déconnexion par inactivité.
- Interface soignée et adaptative (système de design partagé).
- Backend qui compile.

**Faiblesses**
- **Le contrôle d'accès repose essentiellement sur le masquage des écrans Flutter** : l'API laisse n'importe quel utilisateur connecté lire les salaires, approuver des congés, recalculer la paie ou justifier des absences.
- Secrets et mots de passe par défaut permettant une prise de contrôle totale si la configuration n'est pas surchargée.
- Plusieurs parcours affichés mais cassés (manager, candidature publique, CV, type de congé) et plusieurs écrans simulés (données fictives, permissions et paramètres sans effet).
- Règles de paie et de congés simplistes, à faire valider par le métier.
- Quasi-absence de tests automatisés et de CI.

**Travail restant (estimation qualitative)** : le lot 1 (sécurité) est prioritaire et relativement ciblé (annotations, service d'autorisation, configuration). Les lots 2 et 3 représentent l'essentiel de l'effort, en particulier le workflow de congés et la paie, qui dépendent de décisions métier. Aucune réécriture globale n'est nécessaire : des corrections ciblées module par module suffisent.

### Informations métier nécessitant confirmation
1. Modèle de déploiement : une instance par PME ou SaaS mutualisé multi-entreprise ?
2. Règles de paie applicables (taux CNSS salarié/employeur, barème de l'impôt sur le revenu, indemnités, mentions du bulletin).
3. Règles de congés : jours ouvrés ou calendaires, acquisition, fériés, types autorisés (exceptionnel, paternité…), circuit de validation (manager seul, RH seul, ou double).
4. Visibilité des salaires pour les managers et la direction.
5. Politique de pointage : géorepérage, QR dynamique, rôle de « borne ».
6. Formules officielles des indicateurs (turnover, taux de présence).
