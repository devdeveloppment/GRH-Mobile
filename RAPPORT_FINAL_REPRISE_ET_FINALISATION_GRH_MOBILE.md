# Rapport final — Reprise et finalisation de GRH-Mobile (lots 2, 1, 3 et 5)

**Date :** 1er novembre 2026 · **Branche :** `reprise/lot-0` · **Dépôt :** https://github.com/devdeveloppment/GRH-Mobile (public)
**Documents de référence :** `BENCHMARK_ODOO_ET_STRATEGIE_INNOVATION_RH.md`, `RAPPORT_REPRISE_ET_PLAN_STRATEGIQUE_GRH_MOBILE.md`, `docs/EXPLOITATION.md`

---

## 1. Résumé exécutif

- Les quatre lots autorisés ont été réalisés dans l'ordre (2 → 1 → 3 → 5). Les 27 commits sont poussés sur `reprise/lot-0`, sans forçage. `main` n'a pas été touchée et rien n'a été déployé.
- **Tests exécutés réellement :**
  - backend : **16 tests unitaires et 54 tests d'intégration**, tous verts, sur PostgreSQL 17 (Testcontainers) ;
  - Flutter : **43 tests unitaires** ;
  - test d'intégration par rôle sur l'**émulateur Pixel 6** : **4 rôles, 0 problème**, après la dernière migration.
- **Bugs graves trouvés et corrigés en route :**
  1. le journal d'audit n'avait **jamais** rien enregistré, et faisait échouer en 500 les opérations auditées (par exemple l'approbation d'un congé) ;
  2. la paie appliquait des **taux inventés**, présentés comme « CNSS » ;
  3. les fichiers `uploads/` (CV, documents RH, justificatifs) étaient **téléchargeables par tout utilisateur connecté**, sans aucun contrôle ;
  4. les données de démonstration se créaient **en production** dès que la base était vide.
- **Le multi-entreprise est réellement en place**, avec deux barrières indépendantes : filtre Hibernate `@TenantId` et RLS PostgreSQL. L'isolation est vérifiée par 12 tests, avec un rôle applicatif sans `BYPASSRLS`.
- **Le produit n'est pas prêt pour la production.** Il reste notamment :
  - la validation de la paie par un expert-comptable ;
  - un test de sauvegarde et de restauration ;
  - un test sur téléphone physique ;
  - l'interface web de gestion des entreprises ;
  - un compte chez un fournisseur d'IA pour activer l'assistant.

## 2. État initial (après le lot 0)

- 7 commits de sécurisation, sauvegarde `E:\meweprojects\_backups\GRH-Mobile_lot0_20261101\` (non modifiée).
- Points hérités et leur traitement :

| Point | Traitement |
|---|---|
| `rh_dashboard.dart` supprimé localement | **Restauré** (`git restore`). C'est l'ancien tableau de bord RH, remplacé dans le routeur par `rh_dashboard_modern.dart` ; il compile toujours. Toute suppression future devra être décidée. |
| Commit `50f5f2d` | Son message mentionne Linux, mais les fichiers Linux n'avaient que des différences de fins de ligne. **Historique non réécrit.** |
| Identifiants en clair dans le test d'intégration | Remplacés par `--dart-define-from-file` (fichier local ignoré par Git, modèle fourni). |
| Asset `.env` | Retiré des assets : un clone neuf compile. Configuration via `.env.example` versionné, surchargeable par `--dart-define-from-file=.env`. |
| Migrations V7 à V9 absentes | Laissées telles quelles. Les nouvelles migrations sont **V28 à V32**. |

Le dépôt officiel était vide. J'ai ajouté un remote `officiel` sans modifier `origin`, qui pointe vers `Tango03-12/GRH-Mobile`.

## 3. Travaux réalisés par lot

### Lot 2 — Stabilisation
- Audit JSONB : mapping corrigé (`@JdbcTypeCode(SqlTypes.JSON)`) et journal écrit dans une transaction indépendante (`REQUIRES_NEW`).
- Filtres d'audit (typage de `null` sous PostgreSQL 17) et `LazyInitializationException` (évaluations de l'employé) corrigés. Les autres contrôleurs ont été passés en revue et testés : aucune autre occurrence observée.
- Écrans : largeur infinie de l'en-tête Employés (rôle RH). Cause : le thème impose `minimumSize: Size.fromHeight`. Débordement de la tuile Évaluations (ADMIN) corrigé aussi.
- Données de démonstration déplacées dans le profil Spring `demo`, idempotentes, refusées avec `prod`, couvrant tous les modules. Auparavant, elles étaient créées dans n'importe quel profil.
- Tests d'intégration backend sur un vrai PostgreSQL (Testcontainers 1.21.3, Failsafe, `api.version=1.44` pour Docker Desktop récent).
- README factuel et procédure d'installation depuis un clone neuf.

### Lot 1 — Mise à niveau RH
- **Moteur de paie paramétrable** :
  - rubriques avec formules dans un langage restreint, sans exécution de code ;
  - paramètres datés et sourcés, jamais supprimés ;
  - lignes de bulletin tracées ;
  - **aucun taux réglementaire fourni**. Un bulletin n'est « conforme » que si chaque retenue légale repose sur un paramètre validé (source + validateur) ; sinon il porte la mention « SIMULATION », PDF compris.
- **Congés** : mode de décompte paramétrable (calendaires par défaut, comportement inchangé ; ouvrables ; ouvrés), jours fériés saisis par l'entreprise, acquisition mensuelle planifiée et idempotente (désactivée tant que le nombre de jours n'est pas renseigné), aperçu du décompte.
- **Heures supplémentaires** : quantités calculées au-delà de la durée normale paramétrée (vide = désactivé). Les majorations relèvent de la paie validée.
- **Notes de frais** : justificatif contrôlé par sa signature binaire, validation jamais faite par le demandeur, refus motivé, remboursement **déclaré manuellement** avec une référence obligatoire. Aucun paiement n'est effectué ni simulé.
- **Listes d'arrivée et de départ** des employés.
- **Alertes automatiques** de fin de contrat, envoyées une seule fois.
- Écrans Flutter : Notes de frais, Paramétrage RH, bandeau « SIMULATION » sur la paie, correction de l'espace employé (taux inventé « CNSS (4%) » et doublon Primes/Indemnités).

### Lot 3 — Assistant RH
- Comparaison des fournisseurs : voir § 9.
- Intégration via le **SDK Java officiel de Claude** : boucle d'outils en lecture seule, 5 outils fixes (pas de SQL généré), droits revérifiés côté serveur à chaque appel, seuls les outils autorisés pour le rôle proposés au modèle, **minimisation** (matricules, dates et agrégats ; les noms sont résolus côté serveur pour l'affichage), consigne explicite « aucune décision RH », journalisation dans l'audit.
- **Désactivé par défaut**, faute de clé : je n'ai inventé aucune clé et souscrit à aucun service. Dans ce cas, l'API renvoie 503 et l'écran le dit.
- Écran Flutter « Assistant RH » pour tous les rôles. Il propose aussi des **consultations directes sans IA**, avec des données vérifiables.

### Lot 5 — SaaS multi-entreprise
- Détail au § 6. Également livrés :
  - API plateforme pour le SUPER_ADMIN (créer, suspendre, réactiver une entreprise, changer d'offre) ;
  - initialisation des données propres à chaque nouvelle entreprise ;
  - tâches planifiées exécutées entreprise par entreprise ;
  - pages publiques par entreprise (`?entreprise=<slug>`) ;
  - suppression de l'exposition statique de `uploads/` ;
  - guide d'exploitation `docs/EXPLOITATION.md`.

## 4. Fonctionnalités créées, corrigées ou améliorées (synthèse)

**Créées :**
- moteur de paie paramétrable ;
- jours fériés et décompte des congés ;
- acquisition des congés ;
- heures supplémentaires ;
- notes de frais ;
- listes d'arrivée et de départ ;
- alertes de contrats ;
- assistant RH ;
- multi-entreprise et API plateforme ;
- profil de démonstration ;
- tests d'intégration backend et Flutter.

**Corrigées :**
- audit (JSONB, rollback silencieux, filtres) ;
- évaluations de l'employé (500) ;
- tableau de bord admin (null check sur le rôle) ;
- cartes KPI (bordure) ;
- écrans Employés et Évaluations ;
- paie (taux inventés, libellés « CNSS ») ;
- exposition des fichiers ;
- seeder actif en production ;
- configuration `.env`.

## 5. Architecture finale et choix techniques

- Inchangée sur le fond : Spring Boot 3.3, JPA/Hibernate 6.5, Flyway, JWT, Flutter, Riverpod, go_router.
- Dépendances ajoutées :
  - `anthropic-java` 3.2.0 (assistant) ;
  - Testcontainers 1.21.3 et `spring-boot-testcontainers` (tests uniquement) ;
  - `integration_test` (développement Flutter).
- Nouveaux paquets backend : `tenant` (contexte d'entreprise, résolveur Hibernate, fournisseur de connexion RLS, filtre de requête) et `assistant`.

## 6. Multi-entreprise et résultats des tests d'isolation

**Conception (décisions D1 à D3) :**
- V32 ajoute la table `entreprises` et la colonne `entreprise_id` sur 30 tables ; les données existantes sont rattachées à l'entreprise n° 1, sans perte, sur la base de développement réelle.
- Les unicités deviennent propres à chaque entreprise ; l'e-mail de connexion reste unique sur toute la plateforme ; les permissions restent communes.
- Barrière 1 : Hibernate `@TenantId` filtre et renseigne `entreprise_id`.
- Barrière 2 : RLS activée **et forcée**. La variable `app.entreprise_id` est posée sur chaque connexion ; sans elle, aucune ligne n'est visible (fail closed).
- L'entreprise courante vient **de l'utilisateur authentifié**, jamais d'un paramètre client. Une entreprise suspendue est refusée à la connexion et sur les jetons déjà émis.
- Seule requête native du projet (recherche d'employés) : filtre explicite ajouté.

**Découverte importante :** un superutilisateur PostgreSQL contourne la RLS. Les premiers tests passaient par le filtre Hibernate seul : la RLS n'était donc pas réellement testée. La suite utilise maintenant **deux rôles** (propriétaire pour Flyway, rôle applicatif ordinaire), comme exigé en production (`docs/EXPLOITATION.md` § 2). En local, `grh` n'est pas superutilisateur et `FORCE` s'applique.

**Tests d'isolation (`MultiEntrepriseIT`, 12/12 verts) :**

| Couverture | Résultat |
|---|---|
| RLS sans entreprise définie | 0 ligne visible |
| RLS en lecture croisée | 0 ligne de l'autre entreprise |
| RLS : insertion dans une autre entreprise | refusée par PostgreSQL |
| RLS : mise à jour croisée | 0 ligne modifiée |
| 24 listes de l'API, dans les deux sens | aucune fuite (matricules, e-mails, noms) |
| Accès par identifiant (employé, documents, paie, document, congé) | 403 ou 404, aucune modification |
| Recherche native | cloisonnée |
| Outils de l'assistant | cloisonnés |
| Pages publiques par entreprise ; entreprise inconnue | cloisonnées ; aucune donnée |
| Fichiers en statique | non servis |
| API plateforme | réservée au SUPER_ADMIN |
| Suspension | connexion et jetons existants refusés (403) |
| Création d'entreprise | données initialisées ; e-mail déjà pris refusé (D2) |

**Limites honnêtes :**
- les traitements asynchrones sont couverts pour les 3 tâches planifiées existantes ; il n'existe pas d'autre traitement asynchrone ;
- l'export de rapports (`/api/reports/export`) a été passé en revue mais pas testé spécifiquement entre entreprises ;
- les fichiers stockés sur disque ne sont pas séparés par répertoire d'entreprise : leur isolation repose sur les endpoints contrôlés (entités filtrées) ;
- la restauration d'une seule entreprise n'est pas outillée.

## 7. Sécurité

**Corrigé :**
- exposition statique de `uploads/` ;
- seeder de démonstration en production ;
- audit inopérant ;
- identifiants retirés du code de test ;
- contrôle du type réel des justificatifs ;
- isolation entre entreprises ;
- suspension.

**Restant (non traité dans ces lots) :**
- jeton de 8 h sans révocation (une désactivation n'agit qu'au rechargement de l'utilisateur, à chaque requête ; l'entreprise suspendue, elle, est bloquée immédiatement) ;
- aucune limitation de débit sur les endpoints publics (connexion, candidature) ;
- dépôt de CV public contrôlé par l'extension seulement (le contrôle par signature n'est appliqué qu'aux notes de frais) ;
- l'historique Git contient un ancien `backend/.env` (commit `ce4d835`). Vérification faite sans afficher les valeurs : il ne contient que les **valeurs d'exemple** (le JWT « change-me » et le mot de passe de développement du `docker-compose`). Ces valeurs ne doivent jamais servir en production.

## 8. Paie et limites réglementaires

**Aucune règle CNSS, IRPP ni disposition du Code du travail n'a été saisie** (décision D4) : aucun expert-comptable n'a été identifié. Le moteur est prêt :
- l'expert saisit les paramètres datés et leur source ;
- il les valide (`PUT /api/paie/parametres/{id}/validation`) ;
- il crée les rubriques correspondantes.

D'ici là, tout bulletin porte la mention « SIMULATION — ne constitue pas un bulletin légal ». L'interface Flutter de configuration des rubriques et des paramètres **n'est pas réalisée** : seule l'API existe, testée.

## 9. Assistant IA : fournisseurs et prérequis

Sources consultées le 1er novembre 2026. Prix par million de tokens, tels qu'affichés.

| Critère | Anthropic (Claude) | Mistral |
|---|---|---|
| Modèles | Haiku 5.5, Sonnet 5.5, Opus 5.5 (contexte 1 M) | Small 4, Large 4 |
| Prix (entrée / sortie) | Haiku 0,10 $ / 0,50 $ ; Sonnet 2 $ / 10 $ ; Opus 4 $ / 20 $ ; lots −50 % | Small 0,15 $ / 0,6 $ ; Large 0,7 $ / 2,1 $ (une page FAQ indique d'autres chiffres pour Large : **à vérifier**) |
| Appel d'outils | Oui, SDK Java officiel | Oui (Small 4 vérifié ; Large non vérifié) |
| Entraînement sur les données | Conditions commerciales : pas d'entraînement sur le contenu client | DPA : entraînement possible **sauf opt-out** |
| Localisation | Entité irlandaise pour l'EEE ; pas d'hébergement UE explicite trouvé | Société française ; hébergement UE non confirmé dans les pages lues |

**Choix technique :** l'intégration est réalisée avec le SDK Claude, faute d'équivalent Java officiel vérifié chez Mistral. Le modèle est configurable ; la valeur par défaut, `claude-opus-5-5`, est celle recommandée par la documentation du SDK. Le choix du modèle et du fournisseur reste **à votre décision** (D5), après un prototype mesuré.

**Prérequis restants :**
- compte et clé API (`ANTHROPIC_API_KEY`) ;
- `AI_ENABLED=true` ;
- signature du DPA ;
- information des salariés.

Le refus « fallback » côté serveur n'est pas activé : un refus du modèle renvoie un message neutre.

## 10. Préparation SaaS

**Fait :**
- isolation ;
- entreprises et offres (déclaratives) ;
- suspension ;
- initialisation des données par entreprise ;
- super-administrateur ;
- guide d'exploitation (rôles, sauvegarde, supervision, liste de contrôle).

**Non fait :**
- facturation et paiement (volontairement : aucun paiement simulé) ;
- interface web de la plateforme ;
- restauration testée ;
- supervision branchée sur un outil ;
- documentation commerciale (une proposition de positionnement figure dans le benchmark).

## 11. Résultats des tests

| Suite | Résultat | Environnement |
|---|---|---|
| Backend unitaires | 16/16 (1 test de contexte ignoré : il nécessite `DB_URL`) | Maven |
| Backend intégration | 54/54 : `RolePermissionsIT` 26, `Lot1FonctionnalitesIT` 10, `MultiEntrepriseIT` 12, `AssistantIT` 4, `CongeWorkflowIT` 2 | PostgreSQL 17 (Testcontainers), rôle sans BYPASSRLS |
| Flutter `analyze` | 0 erreur, 0 avertissement (environ 150 remarques de style) | — |
| Flutter `test` | 43/43 | — |
| Flutter intégration par rôle | 4/4 rôles, 0 problème (après V32) | **émulateur** Pixel 6, Android 16 |
| Téléphone physique | **non testé** | — |
| Web (Chrome) | lancement vérifié manuellement plus tôt ; test d'intégration **non exécuté** (pas de chromedriver) | — |

## 12. Captures d'écran

43 captures réelles ont été prises sur l'émulateur (tous les écrans des 4 rôles, dont les écrans modifiés : Employés, Évaluations, Paie, Notes de frais, Paramétrage RH, Assistant).

**Elles ne sont pas versionnées :** la base de développement contient **des données personnelles réelles** (trois comptes avec des adresses Gmail, visibles sur l'écran Utilisateurs). Elles sont rangées hors du dépôt dans `E:\meweprojects\_captures_locales_NE_PAS_PUBLIER_20261101\`. Pour des captures publiables, il faut les reprendre sur une base neuve lancée avec le profil `demo` (`--dart-define=GRH_CAPTURES=true`).

## 13. Migrations Flyway

V1 à V6, V10 à V27 (existantes, non modifiées), puis :
- V28 : moteur de paie ;
- V29 : paramètres RH, jours fériés, acquisitions ;
- V30 : notes de frais ;
- V31 : listes d'arrivée et de départ, anti-doublon des alertes ;
- V32 : multi-entreprise et RLS.

Toutes sont appliquées sur la base de développement et sur les bases de test.

## 14. Commits par lot

| Lot | Commits |
|---|---|
| 0 | `4f5a54f` `8096e7c` `1e5c871` `35b6141` `51e0f14` `50f5f2d` `37bfad3` |
| 2 | `6d3a69b` audit · `c3ff9f7` profil demo · `add53c5` tests backend · `43cdfd8` config `.env` · `b3a33a1` README · `0671fb8` écrans · `067f4c3` test Flutter |
| 1 | `09622ab` paie · `a316391` congés/fériés/heures sup · `75ce908` notes de frais · `e926bea` arrivée/départ + alertes · `c521cae` tests · `7e49e88` écrans Flutter |
| 3 | `3938a59` assistant backend · `104489e` écran assistant |
| 5 | `f6b7c15` isolation · `15793c0` entreprises et traitements · `cc017c4` tests d'isolation · `fefcf6f` guide d'exploitation |

## 15. Dépôt Git et push

- Pushs sur `officiel/reprise/lot-0` uniquement, en avance rapide (fast-forward), sans forçage ; aucune branche distante supprimée.
- Le dépôt étant vide au premier push, la **branche par défaut sur GitHub est `reprise/lot-0`** : à modifier si vous souhaitez une `main` distante.
- GitHub signale des fichiers de plus de 50 Mo dans d'**anciens** commits (`build/`, avant le lot 0). L'historique n'a pas été réécrit.
- Le dépôt est **public** : les documents et le code y sont visibles.
- Toujours non suivis localement : `ios/`, `macos/`, `windows/`, `android_backup/` (décision D7).

## 16. Reste à terminer

- Interfaces Flutter : configuration de la paie (rubriques et paramètres), listes d'arrivée et de départ, administration de la plateforme.
- Révocation des jetons et limitation de débit ; contrôle par signature des CV publics.
- Tests : export de rapports entre entreprises, parcours d'écriture côté Flutter (création d'un congé, d'une note de frais depuis l'interface), Chrome, téléphone physique.
- Restauration testée ; supervision branchée.
- Mode hors ligne, SMS/WhatsApp, mobile money, import Excel (benchmark) : **non réalisés**.

## 17. Dépendances externes et validations humaines

- **Expert-comptable ou juriste** : règles CNSS, IRPP, congés, durée du travail, jours fériés.
- **Fournisseur d'IA** : compte, clé, DPA, choix du modèle.
- **Hébergement** : création des deux rôles PostgreSQL, HTTPS, secrets (`JWT_SECRET`).
- **Décision** : branche par défaut GitHub, sort des dossiers de plateformes non suivis, publication de captures sur données de démonstration.

## 18. Risques et recommandations

1. Ne jamais connecter l'API avec un superutilisateur : la RLS serait contournée, sans que l'application le signale.
2. Toute migration future qui touche des données doit poser `app.entreprise_id = -1` (documenté).
3. Retirer les comptes personnels réels de la base de développement, ou utiliser une base `demo`.
4. Faire valider la paie avant toute utilisation réelle.
5. Traiter la révocation des jetons et la limitation de débit avant une ouverture publique.

## 19. Maturité du produit (évaluation honnête)

| Domaine | Statut |
|---|---|
| Authentification, rôles, permissions | Terminé et testé |
| Isolation multi-entreprise (API + RLS) | Terminé et testé |
| Audit | Terminé et testé |
| Congés (décompte, fériés, acquisition) | Terminé et testé (backend) ; interface partielle (paramétrage) |
| Notes de frais | Terminé et testé (backend) ; écran vérifié à l'ouverture, parcours de saisie non automatisé |
| Heures supplémentaires | Terminé et testé (quantités) |
| Listes d'arrivée et de départ | Partiellement terminé (API testée, pas d'écran) |
| Alertes automatiques | Terminé et testé |
| Moteur de paie | Partiellement terminé : technique testée ; **en attente de validation externe** pour les règles |
| Assistant RH | Terminé mais non testé avec un vrai modèle : **en attente d'une clé** ; couche outils testée |
| API plateforme (entreprises) | Terminé et testé (API) ; interface non réalisée |
| Sauvegarde et restauration | Documenté, non testé |
| Hors ligne, SMS, mobile money, import Excel | Non réalisé |

**Synthèse :** le produit est une base solide en **pré-production**. Il n'est pas prêt pour des clients réels tant que la paie n'est pas validée et que les points du § 18 ne sont pas traités.

## 20. Prochaines étapes recommandées

1. Identifier l'expert-comptable et saisir puis valider les paramètres de paie togolais.
2. Préparer l'hébergement de pré-production (deux rôles PostgreSQL, HTTPS, secrets), puis tester sauvegarde et restauration.
3. Ajouter la révocation des jetons et la limitation de débit.
4. Réaliser les interfaces restantes (paie, arrivée et départ, plateforme).
5. Ouvrir un compte IA et mesurer l'assistant sur un jeu de questions de référence.
6. Tester sur un téléphone Android physique d'entrée de gamme.
