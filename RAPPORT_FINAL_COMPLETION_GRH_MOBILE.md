# Rapport final — Phase de finalisation technique de GRH-Mobile

Date : 02/11/2026 · Branche : `reprise/lot-0` · Dépôt : https://github.com/devdeveloppment/GRH-Mobile.git
Public visé : porteur du projet et futur responsable technique.

Statuts utilisés : **Terminé et testé** · **Terminé mais non testé** · **Partiellement terminé** ·
**En attente d'une validation externe** · **Non réalisé**.

---

## 1. Résumé exécutif

Les travaux réalisables sans intervention extérieure sont terminés et vérifiés.

- **Sécurité** : jetons de connexion révocables (déconnexion, mot de passe, rôle, désactivation, révocation
  administrative), limitation des requêtes non contournable par changement d'adresse IP, contrôle du contenu
  réel des fichiers, export de rapports testé entre entreprises.
- **Interfaces** : configuration de la paie (circuit de validation), arrivées et départs, gestion des
  entreprises clientes.
- **Nouvelles capacités** : mode hors ligne réel (file chiffrée, synchronisation sans doublon, conflits),
  import Excel contrôlé, socle SMS et mobile money désactivé par défaut.
- **Exploitation** : la procédure de sauvegarde documentée **ne fonctionnait pas** (RLS forcée). Elle est
  corrigée, et une restauration complète a été réussie dans un environnement isolé.
- **Tests** : backend 17 unitaires + 72 d'intégration verts ; Flutter 50 unitaires verts ; sur émulateur
  Pixel 6, audit des pages (4 rôles), parcours d'écriture complet et test hors ligne verts.

Restent bloqués par des prérequis externes : tests Web dans Chrome (ChromeDriver non autorisé dans la
session), téléphone physique, validation réglementaire de la paie, fournisseurs SMS, paiement et IA.
**Le produit n'est pas mis en production et aucune conformité légale n'est déclarée.**

## 2. État initial

Référence : `RAPPORT_FINAL_REPRISE_ET_FINALISATION_GRH_MOBILE.md` (commit `2d552f8`).

À l'audit préalable :
- dépôt local identique à `officiel/reprise/lot-0` ;
- aucune modification non committée, hors `android_backup/`, `ios/`, `macos/` et `windows/`, conservés non suivis ;
- migrations V1–V6 et V10–V32 ;
- nouvelle sauvegarde vérifiée : `E:\meweprojects\_backups\GRH-Mobile_completion_20261101\grh-mobile.bundle`.

Dépôt public (historique complet examiné) :
- aucune clé API, aucune clé privée, aucun keystore ni jeton ;
- l'ancien `backend/.env` (commits `45e54f9`, `ce4d835`) ne contient que les valeurs d'exemple (`grhpassword`, `changeme…`) : rien à révoquer ;
- des artefacts `build/` volumineux (jusqu'à 96 Mo) viennent de l'historique d'origine : ce sont des binaires sans secret. Les supprimer exigerait de réécrire l'historique public : **non fait**, décision laissée au propriétaire ;
- les captures montrant des comptes personnels réels n'ont jamais été versionnées.

## 3. Travaux réalisés (commits)

| Commit | Contenu |
|---|---|
| `08d3596` | Révocation JWT, limitation des requêtes, contrôle réel des fichiers, correction de l'énumération des comptes |
| `8c961f1` | Circuit de validation des paramètres de paie, clôture arrivées/départs, fiche entreprise (API) |
| `a78c7fe` | Trois écrans Flutter, parcours d'écriture de bout en bout, corrections d'erreurs trouvées par ce parcours |
| `83bd79f` | Procédure de sauvegarde corrigée, restauration testée ; sessions, limitation, supervision |
| `c1379b4` | Import Excel des employés ; rejeu hors ligne sans doublon (Idempotency-Key) |
| `7d9a2ed` | Couche SMS / mobile money interchangeable et désactivée ; comparatif des fournisseurs |
| `d9ef2a7` | Mode hors ligne Flutter |
| (ce commit) | `docs/TESTS.md` et ce rapport |

Défauts réels trouvés et corrigés en chemin :
1. Un e-mail inconnu à la connexion provoquait une erreur 500, différente de la réponse à un mauvais mot de passe : cela permettait de deviner quels comptes existent. Désormais, les deux cas renvoient 401.
2. Un 401 sur un ancien jeton (requête partie avant une reconnexion) effaçait la **nouvelle** session.
3. Les fournisseurs de données des congés et de la paie levaient des erreurs non gérées après une déconnexion.
4. La page Audit débordait sur mobile.
5. La commande `pg_dump` documentée échouait.

## 4. Fonctionnalités restantes, désormais traitées

| Fonctionnalité | Statut |
|---|---|
| Révocation des jetons (6 cas) | Terminé et testé |
| Limitation des requêtes (connexion par IP et par compte, mot de passe, candidatures, pages publiques, envois de fichiers, exports, assistant, plateforme) | Terminé et testé (connexion et pages publiques testées ; autres règles terminées mais non testées une à une) |
| Contrôle des fichiers (CV, documents RH, justificatifs) | Terminé et testé |
| Export de rapports entre entreprises (PDF, XLSX, CSV ; 10 combinaisons) | Terminé et testé |
| Interface de configuration de la paie | Terminé et testé (émulateur) |
| Interface arrivées / départs | Terminé et testé (émulateur) |
| Interface entreprises clientes (SUPER_ADMIN) | Terminé et testé (émulateur) |
| Parcours d'écriture Flutter (4 rôles + plateforme, refus des actions interdites) | Terminé et testé (Android) |
| Sauvegarde / restauration | Terminé et testé (démonstration, conteneurs isolés) |
| Mode hors ligne | Terminé et testé (unitaires + émulateur) |
| Import Excel (API) | Terminé et testé ; **écran Flutter : Non réalisé** (API seulement) |
| SMS / WhatsApp | Partiellement terminé (socle) — En attente d'une validation externe |
| Mobile money | Partiellement terminé (socle testé) — En attente d'une validation externe |
| Tests Web Chrome | Non réalisé (outil bloqué, voir § 9) |
| Téléphone physique | Non réalisé (aucun appareil) |

## 5. Fonctionnalités bloquées et raisons

| Élément | Blocage | Pour débloquer |
|---|---|---|
| Règles de paie légales (CNSS, IRPP, plafonds, congés légaux) | Validation d'un expert-comptable ou d'un juriste | Saisir les paramètres avec leur source, puis faire enregistrer la validation par une seconde personne |
| Assistant IA | Clé API, contrat de traitement des données (DPA), information des salariés | `AI_ENABLED=true`, `ANTHROPIC_API_KEY` (voir `docs/EXPLOITATION.md` § 8) |
| SMS | Fournisseur, compte, expéditeur déclaré, budget | Implémenter `FournisseurSms` (voir `docs/INTEGRATIONS_SMS_PAIEMENT.md`) |
| Mobile money | Compte marchand, contrat, sandbox, secrets de signature | Implémenter `FournisseurPaiement` et définir `app.paiement.fournisseur` |
| Tests Chrome | ChromeDriver non autorisé dans la session | `docs/TESTS.md` § 5 |
| Téléphone physique | Aucun appareil | `docs/TESTS.md` § 6 |

## 6. État de la sécurité

- **Isolation entre entreprises** : deux barrières conservées, le filtre applicatif Hibernate (`@TenantId`) et les règles PostgreSQL (RLS). La table `clotures_integration` est aussi sous RLS. Les tables techniques (jetons révoqués, compteurs, idempotence, paiements) n'ont pas de RLS : elles ne contiennent pas de données RH, et l'accès passe par l'utilisateur ou le SUPER_ADMIN.
- **Révocation des jetons** : un jeton contient un identifiant unique et une « version de session ». Ces états sont en base, donc valables quand plusieurs instances tournent. Un jeton absent, révoqué ou falsifié reçoit 401.
- **Limitation des requêtes** : compteurs PostgreSQL partagés entre instances, réponse 429 avec `Retry-After`. L'en-tête `X-Forwarded-For` n'est jamais lu directement ; les seuils sont dans `docs/EXPLOITATION.md` § 5.
- **Fichiers** : le type réel est vérifié par sa signature binaire, ainsi que la concordance avec l'extension. Les noms sont contrôlés et les CV rangés par entreprise.
- **Base de données** : l'application se connecte avec `grh_app` (`NOSUPERUSER`, `NOBYPASSRLS`), vérifié sur la base de démonstration et sur la base restaurée.
- **Risques résiduels** :
  - les photos de profil sont accessibles sans connexion, à condition de connaître leur nom, qui est aléatoire et non devinable ;
  - le Web stocke le jeton dans le navigateur ;
  - il n'y a pas de jeton de rafraîchissement (session de 8 h) ;
  - la validation du corps d'une requête passe avant le contrôle des droits : un utilisateur sans droit reçoit 400 au lieu de 403 sur une requête invalide, sans fuite de données.

## 7. Tests backend

`mvn verify` : **17 tests unitaires (1 ignoré, préexistant) et 72 tests d'intégration, tous verts**, sur PostgreSQL 17 réel (Testcontainers) avec un rôle applicatif sans contournement RLS.

Nouvelles classes :

| Classe | Tests | Objet |
|---|---|---|
| `SecuriteCompletionIT` | 8 | Révocation, fichiers, exports entre entreprises |
| `LimitationRequetesIT` | 2 | Limitation |
| `CompletionFonctionnalitesIT` | 2 | Arrivées/départs, plateforme |
| `ImportEtHorsLigneIT` | 3 | Import Excel, idempotence |
| `PaiementEtSmsIT` | 2 | Règles de paiement (fournisseur fictif de test), SMS |
| `PaiementDesactiveIT` | 1 | Paiement désactivé par défaut |

`Lot1FonctionnalitesIT` a été adapté au circuit de validation de la paie.

## 8. Tests Flutter

- `flutter test` : **50 tests verts**, dont 7 sur la file hors ligne.
- `flutter analyze` : 0 erreur et 0 avertissement. Restent des remarques de style anciennes (`withOpacity`, `const`).

## 9. Tests Web Chrome

**Non réalisés.** Le téléchargement de ChromeDriver 156 (Chrome for Testing) a été refusé par la politique de sécurité de la session. Je ne l'ai pas contourné. Le Web n'est donc **pas** déclaré testé. La procédure exacte est dans `docs/TESTS.md` § 5 ; les tests d'intégration existants sont prêts à être relancés dans Chrome.

## 10. Tests Android (émulateur Pixel 6, Android 16)

Tous contre le backend de démonstration (2 rôles PostgreSQL, V37).

- **`role_pages_audit_test`** : 4/4 rôles, 0 problème, nouveaux écrans compris.
- **`parcours_ecriture_test`** : vert, deux fois dont une en mode capture. Il couvre :
  - création et modification d'un employé ;
  - arrivée cochée et clôturée depuis l'écran, départ dont la clôture est refusée tant que des tâches restent ;
  - congés : demande, approbation, refus ;
  - notes de frais : création, approbation, refus ;
  - consultation des documents, évaluations, congés et frais ;
  - circuit de paie ;
  - plateforme : création, suspension, réactivation depuis l'écran, changement d'offre ;
  - refus vérifiés : 403 pour l'employé, la direction et un administrateur sur la plateforme, et redirection des routes interdites.
- **`hors_ligne_test`** : vert.

## 11. Tests multi-entreprise

- Couverts par les tests d'intégration : listes, accès par identifiant, recherche native, documents, outils de l'assistant, pages publiques, plateforme, suspension.
- **Nouveaux tests** :
  - exports PDF, XLSX et CSV des 4 types de rapports, contrôlés dans les deux sens, avec un témoin positif ;
  - arrivées et départs ;
  - import Excel ;
  - révocation administrative entre entreprises (refusée) ;
  - clés d'idempotence propres à chaque utilisateur.
- Tâches planifiées : elles s'exécutent par entreprise ; les purges ne touchent que des tables techniques.

## 12. Sauvegarde et restauration

1. Sauvegarde `pg_dump` lancée avec `--enable-row-security` et `PGOPTIONS="-c app.entreprise_id=-1"`.
2. Restauration dans un **second conteneur isolé**, avec les rôles `grh_owner` et `grh_app` recréés. `pg_restore` termine avec le code 0.
3. Intégrité : comptages identiques sur 9 tables et empreinte md5 des employés identique.
4. Droits : `grh_app` reste `f|f` (ni superutilisateur, ni contournement RLS) ; 31 tables en RLS forcée. Sans contexte d'entreprise, 0 ligne ; entreprise 1 : 18 employés, entreprise B : 2, sans aucune ligne croisée.
5. API démarrée sur la base restaurée : Flyway « validated 32, up to date » ; connexions réussies ; listes cloisonnées.

La base de développement n'a jamais été utilisée pour cet essai. Restent non testés : la restauration des fichiers `uploads/`, la volumétrie réelle et la durée de restauration.

## 13. Mode hors ligne — Terminé et testé

- **Opérations autorisées** : uniquement les demandes personnelles, c'est-à-dire la demande de congé et la note de frais **sans** justificatif. Paie, validations et permissions exigent le réseau.
- **Stockage** : file Hive chiffrée en AES, clé dans le Keystore (sur le Web, protection moindre).
- **Synchronisation** : à la connexion puis toutes les 30 s, avec `Idempotency-Key` (V36), ce qui empêche tout doublon en cas de rejeu.
- **Conflits** : le motif renvoyé par le serveur est conservé ; un conflit n'est jamais renvoyé automatiquement, l'utilisateur choisit de renvoyer ou de supprimer.
- **Interface** : bandeau global d'état de synchronisation.
- **Limites** :
  - pas de consultation hors ligne complète au-delà du cache Hive existant ;
  - pas de justificatif hors ligne ;
  - la police Inter est téléchargée au premier lancement, puis mise en cache. Hors ligne dès le premier démarrage, la police système s'affiche ; il est recommandé d'embarquer la police.

## 14. Import Excel — API terminée et testée, écran non réalisé

- **Points d'API** : `GET /api/import/employes/modele`, `POST …/apercu` (aucune écriture), `POST /api/import/employes`.
- **Contrôles** :
  - colonnes et formats vérifiés, formules refusées ;
  - doublons détectés dans le fichier et sur toute la plateforme ;
  - import refusé tant qu'une ligne est en erreur (tout ou rien) ;
  - aucune donnée existante modifiée ;
  - import journalisé et cloisonné, 1 000 lignes maximum.
- Les mots de passe temporaires sont renvoyés une seule fois dans le résultat.

## 15. SMS et mobile money

Socle interchangeable, désactivé par défaut :
- un SMS non envoyé est toujours signalé `NON_ENVOYE` ;
- le paiement renvoie 503 sans fournisseur configuré ;
- une notification de paiement à signature invalide est refusée (401) et journalisée ;
- un montant différent du montant attendu met la transaction en échec ;
- une transaction finalisée n'est plus modifiable, et les transactions en attente expirent après 30 minutes.

Comparatif sourcé et prérequis dans `docs/INTEGRATIONS_SMS_PAIEMENT.md`. Les prix y sont **indicatifs** et à confirmer par devis. Aucun compte n'a été créé et aucune dépense engagée.

## 16. Paie

- Le circuit **BROUILLON → SOUMIS → VALIDE** est en place (V34). La personne qui a soumis un paramètre ne peut pas le valider. La validation exige le nom, la qualité du validateur et une source.
- L'interface affiche toujours le statut, et un paramètre non validé reste une « simulation ».
- **Aucun taux n'a été saisi ni inventé.** Les bulletins restent marqués « SIMULATION ».
- L'application trace la déclaration de validation ; elle **ne certifie pas** la conformité.
- Les paramètres validés avant V34 sont migrés au statut VALIDE avec la qualité « AUTRE ». Aucun n'existait en démonstration ; ta base de développement n'a pas été migrée par moi.

## 17. Assistant IA

Inchangé : désactivé faute de clé, lecture seule, droits vérifiés côté serveur, cloisonnement testé. Il est maintenant soumis à la limitation de 30 questions par heure. Aucun compte, aucune clé et aucun DPA n'ont été créés.

## 18. Captures sur données fictives

Dix captures du parcours (Pixel 6), prises sur la base de démonstration uniquement :
- **RH** : employés, arrivées (liste et détail), congés ;
- **Employé** : accueil, notes de frais ;
- **Direction** : évaluations ;
- **Administrateur** : configuration de la paie ;
- **Plateforme** : liste et fiche entreprise.

Elles sont dans `E:\meweprojects\_captures_demo_fictives_20261102\`, hors du dépôt, et je les ai relues visuellement. Je ne les ai pas versionnées (`docs/captures/` est ignoré) ; tu peux les publier si tu le souhaites, elles ne contiennent que des données fictives.

## 19. Migrations ajoutées

| Migration | Contenu |
|---|---|
| V33 | `token_version`, `jetons_revoques`, `limites_requetes` |
| V34 | Statut de validation des paramètres de paie |
| V35 | Responsable et commentaire des tâches, `clotures_integration` (RLS) |
| V36 | `requetes_idempotentes` |
| V37 | `transactions_paiement`, `notifications_paiement` |

Toutes sont additives. Aucune renumérotation et aucune modification de migration existante.

## 20. Commits et push

Les commits du § 3 sont poussés sur `officiel/reprise/lot-0` en avance rapide, après vérification que la branche distante était bien ancêtre de la branche locale.

Rien d'autre n'a été modifié : pas de push forcé, `main` intact, aucune branche supprimée.

## 21. Prérequis humains et externes

1. Faire valider les paramètres de paie par un expert-comptable ou un juriste.
2. Pour l'assistant IA : clé API, DPA et information des salariés.
3. Choisir un fournisseur SMS et un agrégateur mobile money (contrats, sandbox, secrets).
4. Autoriser ChromeDriver, ou exécuter `docs/TESTS.md` § 5.
5. Fournir un téléphone Android physique (`docs/TESTS.md` § 6).
6. Préparer l'hébergement : deux rôles PostgreSQL, HTTPS, CORS, supervision.
7. Tester la restauration sur l'infrastructure cible, y compris les fichiers `uploads/`.
8. Décider du nettoyage éventuel de l'historique public (artefacts `build/`). Cela exige une réécriture de l'historique : je ne l'ai pas faite.

## 22. Risques résiduels

- Le Web n'est pas testé automatiquement, et aucun test n'a eu lieu sur un vrai téléphone.
- Les règles de paie ne sont pas validées.
- Pas d'écran pour l'import Excel.
- Photos de profil publiques (adresses aléatoires, non devinables).
- Pas de jeton de rafraîchissement.
- Les seuils de limitation ne sont réglables que dans le code.
- La police Inter n'est pas embarquée.
- Le dépôt GitHub est public : sa branche par défaut est `reprise/lot-0`.
- Ta base de développement contient trois comptes personnels réels, à ne jamais utiliser pour les tests ni les captures.

## 23. Installation depuis un clone neuf

```bash
git clone https://github.com/devdeveloppment/GRH-Mobile.git && cd GRH-Mobile
git checkout reprise/lot-0
docker compose up -d                       # PostgreSQL de développement
cd backend
export JWT_SECRET=<64 caractères aléatoires>
export SPRING_PROFILES_ACTIVE=demo DEMO_PASSWORD=<mot de passe démo>   # données fictives
mvn spring-boot:run                        # migrations V1…V37 appliquées au démarrage
cd ..
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
```

Pour un environnement proche de la production, voir `docs/EXPLOITATION.md` : deux rôles PostgreSQL, et le profil `demo` est interdit.

## 24. Déploiement futur (non exécuté)

1. Serveur ou PaaS avec Java 17 et PostgreSQL 15 à 17 managé : créer `grh_owner` et `grh_app` (§ 2 du guide).
2. Secrets en variables d'environnement : `JWT_SECRET`, base de données, `CORS_ALLOWED_ORIGINS`, administrateurs.
3. Construire `mvn package` derrière un proxy HTTPS (`server.forward-headers-strategy=native`).
4. Construire `flutter build web` (fichiers statiques sur le même domaine) et `flutter build appbundle`, signé avec un keystore conservé hors Git.
5. Planifier la sauvegarde quotidienne chiffrée et tester la restauration.
6. Mettre en place la supervision de `/actuator/health` et les alertes.
7. Recette sur l'environnement de préproduction, puis décision de mise en service.

## 25. Évaluation honnête de la maturité

- **Niveau atteint** : pré-production solide.
  - La sécurité multi-entreprise, la révocation, la limitation, la sauvegarde et la restauration sont en place et vérifiées.
  - Les parcours RH principaux sont testés de bout en bout sur Android.
- **Avant une ouverture à des entreprises clientes**, il manque :
  - la validation réglementaire de la paie ;
  - les tests Web et sur téléphone physique ;
  - un hébergement réel avec restauration testée sur place ;
  - les contrats des fournisseurs, si SMS, paiement ou IA sont activés.
- **Utilisable dès maintenant** en pilote encadré, sans paie officielle, sur une infrastructure conforme au guide d'exploitation.
