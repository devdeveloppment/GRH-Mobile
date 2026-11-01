# Rapport de reprise et plan stratégique — GRH-Mobile

**Date :** 1er novembre 2026
**Nature :** audit de reprise en lecture seule. Aucun fichier source, aucune base et aucune dépendance n'ont été modifiés pendant cette mission.
**Document de référence :** `BENCHMARK_ODOO_ET_STRATEGIE_INNOVATION_RH.md`

---

## 1. État des lieux réel

### 1.1 État Git (constaté)

| Élément | Valeur |
|---|---|
| Branche | `main` |
| Dernier commit | `863af93` — « ajout du backend complet avec manuel et correction de departement, poste, contrat et le code qr » |
| Fichiers modifiés non commités | **88** |
| Suppressions indexées (`D`) | **95**, toutes dans `build/`. Ce sont des artefacts de compilation retirés de l'index, ce qui est cohérent avec le `.gitignore` modifié. |
| Fichiers et dossiers non suivis (`??`) | **23** |
| Conflits | Aucun |

**Fichiers critiques jamais commités (non suivis) :**

- Migrations `V26__security_hardening.sql` et `V27__permissions_effectives.sql`. **La base locale est déjà en version v27** : un autre poste qui clonerait le dépôt n'aurait pas ces migrations.
- `security/AccessControlService.java`, `security/QrTokenSigner.java`, `util/`, ainsi que les tests `security/`
- `DocumentController.java`, `DocumentService.java`, `PublicOffreController.java`
- `lib/features/profile/change_password_screen.dart`, `employee_detail_panels.dart`, `temporary_password_dialog.dart`
- `integration_test/`, et les dossiers de plateforme `android/`, `web/`, `ios/`, `macos/`, `windows/`
- `README.md`, ainsi que les rapports d'audit et de benchmark

> **Risque n° 1 du projet :** une partie du socle de sécurité et des migrations n'existe que sur ce poste. Une panne de disque ou une mauvaise manipulation les ferait disparaître. Ce n'est pas un problème de code, mais c'est la priorité absolue.

Fichiers modifiés pendant les sessions de travail du 1er novembre 2026, tous non commités :

- Backend : `AuditLogRepository.java` (correction de l'erreur 500 sur l'audit) et `EmployeeController.java` (correction de l'erreur 500 sur les évaluations de l'employé)
- Flutter : `kpi_card.dart`, `employee_list_screen.dart`, `paie_calculation_screen.dart`, `evaluations_screen.dart`, `admin_console_screen.dart`
- Configuration : `pubspec.yaml` (ajout de `integration_test`), `pubspec.lock`, `.env` (port 8081, usage local)

Hors dépôt : des données de démonstration ont été insérées par SQL dans la base locale. Les scripts correspondants sont dans le dossier temporaire de session, pas dans le dépôt.

### 1.2 Backend (constaté)

- **22 contrôleurs, 18 services, 24 entités.** Migrations Flyway V1 à V27, avec `ddl-auto: validate` (le schéma est entièrement piloté par Flyway, ce qui est sain).
- **Sécurité :** JWT stateless, CSRF désactivé (cohérent avec une API stateless), CORS configurable, et permissions fines via `@PreAuthorize("@acl.can('…')")` combinées à des permissions modifiables en base (V27).
- Contrôleurs **sans** `@PreAuthorize` : `Auth`, `Notification`, `Profile`, `PublicOffre`, `QrCode`. C'est attendu pour des endpoints publics ou « `/me` ». Il faut toutefois vérifier dans les services que `Notification`, `Profile` et `QrCode` filtrent bien sur l'utilisateur connecté (lecture rapide : ils passent par `authenticatedUserService.currentUser()` ; à confirmer par des tests).
- **Session :** jeton d'accès valable 8 h (`JWT_EXPIRATION_MINUTES`), **sans refresh token ni révocation côté serveur**. Le secret JWT est vide par défaut et doit être fourni par l'environnement.
- **Tests backend : 3 fichiers** (`GrhMobileApplicationTests`, `AccessControlServiceTest`, `SecurityPrimitivesTest`). Aucun test de service métier (paie, congés, présences…).
- **Audit :** aspect AOP plus table `audit_logs`. Le journal était vide au moment des tests, il faut donc vérifier quelles actions sont réellement tracées.

### 1.3 Frontend Flutter (constaté)

- 18 modules fonctionnels sous `lib/features`, Riverpod, go_router avec contrôle d'accès par route (`canAccess` + permissions), Dio, cache Hive (`CacheService` : lecture et écriture JSON, **sans file de synchronisation**).
- Responsive : bascule sur une barre latérale au-delà de 1120 px (liste des employés) ou 1024 px (console admin), et tiroir en dessous. **Les seuils diffèrent d'un écran à l'autre.**
- Tests : 5 tests unitaires + `integration_test/role_pages_audit_test.dart` (non commité).

### 1.4 Vérification fonctionnelle (méthodes réellement utilisées)

| Méthode | Périmètre |
|---|---|
| Test API automatisé (script) | Endpoints de lecture des 4 rôles : ADMIN, RH_MANAGER, EMPLOYEE, DIRECTION |
| Test d'intégration Flutter (Pixel 6, Android 16) | Connexion et ouverture de chaque page du menu, pour chaque rôle |
| Vérification visuelle | **Aucune** de ma part (pas d'outil de capture). Le test manuel a été confié à l'utilisateur. |
| Bout en bout avec écriture | **Non testé** (création de congé, calcul de paie, embauche…) |

---

## 2. Écarts entre le benchmark et le dépôt actuel

| Point du benchmark | Constat dans le code | Impact |
|---|---|---|
| « 24 migrations Flyway » | 24 fichiers sont suivis par Git, mais **26 existent sur le disque** (V26 et V27 non suivis) | Le benchmark sous-estimait le risque Git |
| Recommandation « commiter les correctifs » | **Plus grave que prévu :** des pans entiers du dépôt ne sont pas suivis | Priorité P0 |
| Tests backend : 3 fichiers | Confirmé, dont 2 non suivis | — |
| Organigramme « présent (API) » | Confirmé (`/departements/organigramme`) ; écran non vérifié | — |
| Débordement Évaluations / Employés RH | Toujours présents (dernier test d'intégration) | Lot 2 |
| Le benchmark ne mentionnait pas les CV publics | Upload de CV **public, sans authentification** (`/api/offres/*/candidatures/upload`), contrôle par **extension seulement** | Nouveau risque, voir §3 |
| Hive « déjà présent » pour le hors ligne | Confirmé, mais il s'agit d'un **simple cache en lecture** : aucune file d'écriture ni synchronisation | L'effort hors ligne est plus important qu'estimé |

---

## 3. Anomalies et risques prioritaires

| # | Risque | Gravité | Constat |
|---|---|---|---|
| R1 | Code critique et migrations **non versionnés** | **Critique** | §1.1 |
| R2 | **Aucune isolation multi-entreprise** | Critique pour le SaaS | Aucun `entreprise_id` dans les 24 entités |
| R3 | Upload de CV public : contrôle par extension uniquement (pas de vérification du type réel), limite de 5 Mo, **pas de limitation de débit** | Élevée | `FileStorageService.storeCv` ; endpoint `permitAll` |
| R4 | Fichiers servis comme ressources statiques (`file:uploads/`). Toute personne authentifiée peut lire n'importe quel fichier dont elle connaît le chemin ; seul le nom aléatoire (UUID) la protège. `/uploads/photos/**` est public. | Élevée (documents RH sensibles) | `application.yml`, `SecurityConfig` |
| R5 | Jeton de 8 h sans refresh ni révocation : un compte désactivé reste actif jusqu'à expiration (sauf si le filtre JWT relit l'état `actif`, **à vérifier**) | Moyenne | `application.yml` |
| R6 | Paie à taux codés en dur | Élevée (enjeu légal) | Seed : 4 % / 8 % / 5 % |
| R7 | Couverture de tests backend quasi nulle | Élevée | 3 fichiers |
| R8 | Deux bugs d'affichage (Évaluations ADMIN, Employés RH) | Moyenne | Test d'intégration |
| R9 | Requêtes JPA sensibles au typage de `null` sous PostgreSQL 17 (audit corrigé ; même motif possible ailleurs) | Moyenne | `AuditLogRepository` |
| R10 | Chargement différé hors transaction (`open-in-view: false`) : d'autres `LazyInitializationException` sont probables | Moyenne | Évaluations de l'employé corrigées ; à rechercher dans les autres contrôleurs |
| R11 | Données de démo ajoutées hors dépôt | Faible | Non reproductible |

---

## 4. Maturité par module

Échelle : **1** = fonctionnel et vérifié · **2** = fonctionnel, partiellement vérifié · **3** = partiellement développé · **4** = visible mais non opérationnel · **5** = non fonctionnel · **6** = absent.

| Module | Code présent | Test automatisé | Lecture vérifiée (API + écran) | Écriture vérifiée | Maturité |
|---|---|---|---|---|---|
| Authentification / rôles / permissions | Oui | Partiel (2 tests sécurité + test d'intégration) | Oui | Connexion oui | **1** |
| Employés | Oui | Non (backend) | Oui (ADMIN, DIRECTION), échec RH à l'écran | Non | **2** |
| Départements / postes | Oui | Non | Oui | Non | **2** |
| Présences / QR | Oui | Non | Oui | Non | **2** |
| Congés | Oui | Non | Oui | Non | **2** |
| Paie | Oui (taux fixes) | Non | Oui | Non | **3** |
| Contrats | Oui | Non | Oui (expirants) | Non | **2** |
| Recrutement | Oui | Non | Oui | Non | **2** |
| Formations | Oui | Non | Oui | Non | **2** |
| Évaluations | Oui | Non | Oui (bug d'affichage ADMIN) | Non | **2** |
| Notifications | Oui (in-app) | Non | Oui | Non | **2** |
| Rapports | Oui | Non | Page OK, export non testé | — | **2** |
| Audit | Oui | Non | Oui (après correctif) | Contenu non vérifié | **2** |
| Portail employé | Oui | Test d'intégration vert | Oui | Non | **1** |
| Hors ligne | Cache en lecture seulement | Non | — | — | **3** |
| Multi-entreprise, notes de frais, heures sup., acquisition de congés, IA, SMS | — | — | — | — | **6** |

---

## 5. Analyse multi-tenant

### 5.1 Comparaison

| Critère | A. Base partagée + `entreprise_id` | B. Un schéma PostgreSQL par entreprise | C. Une base par entreprise |
|---|---|---|---|
| Sécurité | Bonne **si** filtrage systématique (Hibernate `@TenantId` / filtre + RLS PostgreSQL en défense en profondeur) | Très bonne | Excellente |
| Coût d'hébergement | **Le plus bas** | Bas à moyen | Élevé |
| Complexité Spring / JPA | Moyenne (Hibernate 6 gère `@TenantId` nativement) | Élevée (résolution de schéma par requête, Flyway par schéma) | Élevée (pools de connexions multiples) |
| Performance | Bonne avec index `(entreprise_id, …)` | Bonne ; catalogue PostgreSQL alourdi au-delà de centaines de schémas | Bonne, mais beaucoup de connexions |
| Maintenance / migrations | **Une seule migration** | N migrations | N bases |
| Évolutivité | Des milliers de PME | Des centaines | Des dizaines |
| Migration de l'existant | Ajout d'une colonne + rattachement des données à une entreprise par défaut | Déplacement des données | Export / import |

### 5.2 Recommandation

**Option A : base partagée avec colonne `entreprise_id`**, renforcée par :

1. **`@TenantId` d'Hibernate 6** (Hibernate 6.5 est présent) sur une classe parente commune. Le filtrage devient automatique sur toutes les requêtes JPA ;
2. **Row-Level Security PostgreSQL** comme seconde barrière, au cas où une requête native échapperait à JPA ;
3. le tenant est **extrait du JWT** (claim `entreprise_id`), jamais d'un paramètre de requête ;
4. **tests d'isolation obligatoires** : un utilisateur de l'entreprise A ne voit jamais rien de B, endpoint par endpoint.

Pourquoi : la cible (PME, budgets limités, volume potentiellement important) favorise le coût bas et la maintenance unique. L'option C peut rester une offre « premium » plus tard pour les grands comptes.

### 5.3 Conséquences

| Élément | Impact |
|---|---|
| 24 entités | Ajout de `entreprise_id` sur toutes, sauf les tables globales (`permissions`, `flyway_schema_history`). `BaseEntity` existe déjà : c'est le point d'accroche. |
| Contraintes uniques | `email`, `matricule`, `code` département ou poste deviennent uniques **par entreprise**. Exception à trancher : l'e-mail de connexion, global ou par entreprise (voir les décisions). |
| Repositories | Requêtes JPQL filtrées automatiquement par `@TenantId` ; **les requêtes natives sont à auditer une par une** |
| Services / contrôleurs | Peu modifiés si le tenant est injecté par un filtre ; vérifier les `findById` (accès par identifiant d'un autre tenant) |
| Permissions | `permission_roles` : globales ou personnalisables par entreprise (décision) |
| Rôles | Nouveau rôle « super-admin plateforme », distinct de l'admin d'entreprise |
| Flyway | Une migration V28 : création de `entreprises`, ajout des colonnes, entreprise par défaut, index, puis contraintes NOT NULL |
| Données de démo | Rattachées à une « Entreprise Démo » ; idéalement 2 entreprises pour tester l'isolation |
| Fichiers | Chemins de stockage préfixés par l'entreprise, et accès contrôlé (lié à R4) |

**Risques :** fuite entre tenants si une requête native n'est pas filtrée, régressions sur les contraintes uniques, migration de la base existante (à répéter d'abord sur une copie).

---

## 6. Architecture cible (synthèse)

```
Flutter (web / Android) ──JWT(sub, role, entreprise_id)──► Spring Boot
   ├─ Hive : cache + file de synchronisation hors ligne      ├─ TenantFilter → contexte entreprise
   └─ Écran Assistant                                        ├─ Services métier (@TenantId)
                                                             ├─ Moteur de paie (règles versionnées)
                                                             ├─ Service Assistant (outils = services autorisés)
                                                             ├─ Stockage fichiers (accès contrôlé, préfixe tenant)
                                                             └─ PostgreSQL (RLS)  · Notifications (in-app / e-mail / SMS)
```

---

## 7. Moteur de paie togolaise (architecture, sans taux)

> **Aucun taux réglementaire n'est proposé dans ce rapport.** Les règles CNSS (assiettes, plafonds, part salariale et patronale), IRPP (barème, abattements, charges de famille), les heures supplémentaires (majorations) et les jours fériés doivent provenir de **sources officielles** (Code du travail togolais, loi de finances en vigueur, textes CNSS, OTR), puis être **validés par un expert-comptable**.

### 7.1 Modèle de données proposé

| Entité | Rôle |
|---|---|
| `Localisation` (`pays`, `devise`) | Togo d'abord ; d'autres pays ajoutés sans réécriture |
| `ParametrePaie` (`code`, `valeur`, `date_debut`, `date_fin`, `source_reglementaire`) | Taux, plafonds et barèmes **datés et sourcés** : historisation native |
| `RubriquePaie` (`code`, `libelle`, `type` gain / retenue / cotisation, `ordre`, `formule`, `imposable`, `soumis_cotisation`) | Ligne du bulletin |
| `StructureSalariale` | Ensemble ordonné de rubriques, rattaché à une localisation et une catégorie de contrat |
| `ElementVariable` (employé, période, rubrique, montant) | Primes, heures sup., avances, retenues ponctuelles |
| `PeriodePaie` (`ouverte` / `calculée` / `validée` / `clôturée`) | Verrouillage ; pas de recalcul après clôture |
| `LigneBulletin` (rubrique, base, taux, montant, **paramètres utilisés**) | **Traçabilité** de chaque calcul |

### 7.2 Calcul

- Les formules sont évaluées dans un **langage restreint et sûr** (expressions arithmétiques sur des variables nommées : `BASE`, `SBRUT`, `NB_HS`…). **Pas d'exécution de code arbitraire.**
- Ordre : gains → brut → cotisations → imposable → impôt → net.
- Chaque bulletin conserve la **version des paramètres** utilisée, ce qui permet un recalcul identique dans le temps.
- **Tests :** jeux de cas validés par l'expert-comptable, sous forme de tests unitaires « brut X → net Y ».

### 7.3 Ce qui existe aujourd'hui

`FichePaie` stocke brut, cotisations, impôts, indemnités et net, sans détail par rubrique. C'est suffisant pour l'affichage, mais insuffisant pour la conformité et l'audit. Le nouveau modèle peut coexister : l'ancien bulletin reste lisible.

---

## 8. Stratégie IA : assistant RH

### 8.1 Principe

```
Question ─► Backend /api/assistant ─► LLM (avec liste d'OUTILS autorisés pour ce rôle)
                                     ◄─ appel d'outil : ex. contrats_expirant(mois)
            Backend exécute l'outil = méthode de service existante, avec le JWT de l'utilisateur
                                     ─► résultat ─► LLM rédige la réponse en citant les données
            Journalisation (question, outils appelés, réponse) dans audit_logs
```

- **Aucun SQL généré par le modèle.**
- **Outils = services existants** (`ContratService`, `PresenceService`, `CongeService`, `PaieService`…), filtrés par rôle **côté serveur**.
- **Données minimisées** envoyées au fournisseur : pas de salaire individuel ni de pièce d'identité, sauf nécessité et droit.
- **Lecture seule** au départ. Aucune action (valider un congé…) sans confirmation explicite de l'utilisateur dans l'interface.

### 8.2 Outils initiaux (correspondant aux questions de la mission)

| Question | Outil | Rôles |
|---|---|---|
| Contrats qui expirent ce mois | `contrats_expirant(jours)` | ADMIN, RH |
| Employés absents aujourd'hui | `absents(date)` | ADMIN, RH, DIRECTION |
| Masse salariale prévisionnelle | `masse_salariale(periode)` | ADMIN, DIRECTION (RH selon permission) |
| Solde de congés | `solde_conges(employe)` ; l'employé n'accède qu'au sien | Tous |
| Congés en attente | `conges_en_attente()` | ADMIN, RH, manager |

### 8.3 Fournisseurs possibles (à arbitrer)

| Option | Avantages | Points d'attention |
|---|---|---|
| Anthropic Claude (API) | Appel d'outils robuste, bon niveau en français | Coût à l'usage, données hors du Togo, contrat de traitement à signer |
| OpenAI (API) | Écosystème large | Mêmes points |
| Google Gemini (API) | Tarifs bas sur les petits modèles | Mêmes points |
| Mistral (API, UE) | Hébergement européen, bon français | Qualité de l'appel d'outils à tester |
| Modèle ouvert auto-hébergé (Llama, Mistral, Qwen…) | Données sous contrôle | Coût GPU, maintenance, qualité moindre sur petit budget |

> **Les prix évoluent souvent ; ils sont à relever sur les pages officielles au moment du choix.** Recommandation de méthode : un prototype avec deux fournisseurs, évalué sur les 5 questions ci-dessus (exactitude, respect des droits, coût par question), puis une décision.

---

## 9. Feuille de route révisée

| Ordre | Lot | Contenu | Pourquoi à ce rang |
|---|---|---|---|
| **0** | **Sécurisation du dépôt** (nouveau) | Commit des fichiers non suivis et des correctifs, `.gitignore` propre, branche de travail | Risque R1 |
| 1 | **Lot 2 — Stabilisation** | Bugs d'affichage, tests de services backend, recherche des motifs R9 et R10, seed de démo dans le dépôt, tests d'écriture de bout en bout | Base saine |
| 2 | **Conception multi-tenant** (anticipée) | Décisions §12, V28 sur une copie de base, tests d'isolation | Touche toutes les tables : avant le lot 1 |
| 3 | **Lot 4 (partie sécurité)** | R3, R4, R5 : accès contrôlé aux fichiers, validation du type réel, limitation de débit, refresh token ou révocation | Prérequis d'un SaaS |
| 4 | **Lot 1 — Mise à niveau** | Congés (acquisition, jours fériés), heures sup., **moteur de paie** (structure), notes de frais, onboarding, recrutement configurable, notifications | Fonctions attendues |
| 5 | **Paie Togo** | Paramètres validés par l'expert-comptable, cas de test | Dépend du moteur et de la validation externe |
| 6 | **Lot 3 — IA et innovation** | Assistant (prototype → production), hors ligne (file de synchronisation), SMS, mobile money, documents | Différenciation |
| 7 | **Lot 5 — Commercialisation** | Configuration par entreprise, abonnements, sauvegardes, supervision, documentation | Mise sur le marché |
| ∞ | **Lot 4 (reste)** | Performance, accessibilité, Android entrée de gamme, observabilité | En continu |

---

## 10. Plan d'exécution et dépendances

```
Lot 0 ─► Lot 2 ─► Conception MT ─► Sécurité (R3–R5) ─► Lot 1 ─► Paie Togo ─► Lot 3 ─► Lot 5
                                              ▲                    ▲
                        Décisions §12 ────────┘   Expert-comptable ┘
```

| Étape | Livrables | Fichiers principaux | Dépend de |
|---|---|---|---|
| 0 | Historique Git complet | Tout le dépôt | Ton accord |
| 2.1 | Bugs d'affichage | `evaluations_screen.dart`, `employee_list_screen.dart` | 0 |
| 2.2 | Tests de services (Testcontainers PostgreSQL) | `backend/src/test/...` | 0 |
| 2.3 | Seed de démo versionné | `DataSeeder.java` ou profil `demo` | 0 |
| MT.1 | Migration `entreprises` + `entreprise_id` | `V28__multi_tenant.sql`, `BaseEntity`, `JwtAuthenticationFilter` | Décisions D1 à D3 |
| MT.2 | Tests d'isolation | Nouveaux tests | MT.1 |
| S.1 | Endpoint de téléchargement contrôlé, suppression du service statique | `SecurityConfig`, `DocumentController`, `application.yml` | MT.1 (préfixe tenant) |
| 1.x | Fonctionnalités du lot 1 | Services concernés + migrations | MT.1 |
| P.1 | Moteur de paie | Nouvelles entités §7 | 1.x (heures sup.) |
| IA.1 | Prototype d'assistant | `assistant/` (backend), écran Flutter | 2.2, S.1, D5 |

---

## 11. Critères d'acceptation par lot

| Lot | Critères |
|---|---|
| 0 | `git status` propre ; un clone neuf compile et démarre ; Flyway passe de V1 à V27 sur une base vide |
| 2 | Test d'intégration vert pour les **4 rôles** ; au moins 60 % de couverture sur les services métier ; un parcours d'écriture par module (créer, valider) testé ; seed reproductible |
| MT | Deux entreprises de démo ; **aucun** endpoint ne renvoie de données de l'autre (test automatisé sur chaque endpoint) ; RLS active ; migration jouée sur une copie de base sans perte |
| Sécurité | Un document n'est accessible qu'au propriétaire ou au rôle autorisé ; un upload de faux PDF est refusé ; limitation de débit sur les endpoints publics ; un compte désactivé est bloqué en 15 minutes au plus |
| 1 | Chaque fonctionnalité a des tests unitaires + un test d'intégration Flutter ; aucune régression du lot 2 |
| Paie Togo | 100 % des cas validés par l'expert-comptable passent ; chaque ligne de bulletin cite ses paramètres et leur source |
| 3 (assistant) | Au moins 90 % de réponses exactes sur un jeu de questions de référence ; 0 réponse hors des droits du rôle ; toutes les interactions journalisées ; aucune action sans confirmation |
| 5 | Création d'une entreprise cliente en moins de 10 min ; sauvegarde et restauration testées ; supervision active |

---

## 12. Décisions nécessitant ton arbitrage

| # | Décision | Options | Ma recommandation |
|---|---|---|---|
| D1 | Architecture multi-tenant | A partagée / B schémas / C bases | **A** (+ RLS) |
| D2 | Unicité de l'e-mail de connexion | Globale (un e-mail = une entreprise) / par entreprise (sélection de l'entreprise à la connexion) | **Globale** pour commencer (plus simple) |
| D3 | Permissions | Globales / personnalisables par entreprise | Globales au départ, personnalisables plus tard |
| D4 | Expert-comptable ou juriste pour la paie togolaise | Qui, quand | Indispensable avant le lot « Paie Togo » |
| D5 | Fournisseur d'IA et hébergement des données | Voir §8.3 | Prototype comparatif sur 2 fournisseurs |
| D6 | Commit de l'état actuel (lot 0) | Commit unique / commits thématiques ; branche `main` ou branche dédiée | Commits thématiques sur une branche `reprise/lot-0` |
| D7 | Fichiers de plateforme non suivis (`ios/`, `macos/`, `windows/`, `android_backup/`) | Versionner / ignorer / supprimer | Versionner `android/` et `web/` ; décider pour les autres ; **ne pas supprimer** `android_backup/` sans ton accord |
| D8 | Données de démo | Profil Spring `demo` / migration dédiée | Profil `demo` (jamais en production) |

---

## 13. Recommandations

1. **Lot 0 immédiatement** : versionner le code et les migrations non suivis. C'est le risque le plus élevé, et le moins coûteux à traiter.
2. Stabiliser (lot 2) avant toute nouvelle fonctionnalité.
3. Trancher D1 à D3, puis concevoir le multi-tenant **avant** le lot 1.
4. Corriger R3 et R4 (fichiers RH) avant toute mise en ligne publique.
5. Construire le moteur de paie générique d'abord, puis brancher les paramètres togolais une fois validés.
6. Prototyper l'assistant sur des outils en lecture seule, avec deux fournisseurs.
7. Hors ligne : concevoir la file de synchronisation (Hive) avec horodatage et gestion des conflits.

---

*Rapport produit en lecture seule. Seul ce fichier a été créé. En attente de validation avant tout développement.*
