# Benchmark Odoo et stratégie d'innovation RH — GRH-Mobile

**Date de l'analyse :** 1er novembre 2026
**Version Odoo étudiée :** documentation officielle 18.0 + page tarifaire odoo.com
**Périmètre de notre application :** dépôt `GRH-Mobile` (backend Spring Boot, frontend Flutter web/Android), branche `main`, état de travail local du 1er novembre 2026

---

## 1. Résumé exécutif

- **Odoo** couvre l'essentiel de la gestion RH : employés, recrutement, congés avec plans d'acquisition, présences (kiosque, géolocalisation, heures supplémentaires), paie, évaluations (dont 360°), parrainage, flotte, dépenses. Mais sa **paie n'est localisée que pour quelques pays** (Australie, Belgique, Égypte, Hong Kong, Jordanie, Émirats arabes unis). **Aucun pays d'Afrique de l'Ouest francophone** n'apparaît dans la documentation consultée. Son IA RH documentée se limite à l'**OCR de CV et de justificatifs, facturée en crédits**.
- **GRH-Mobile** couvre déjà la plupart des domaines RH de base. 22 contrôleurs REST, 24 entités et 18 modules Flutter sont en place. Une partie est vérifiée de bout en bout, mais plusieurs modules restent **moins avancés** qu'Odoo : congés sans plans d'acquisition, présences sans gestion des heures supplémentaires, paie avec un calcul simplifié, recrutement sans étapes configurables.
- **Ce qui manque le plus :** plans d'acquisition de congés, heures supplémentaires, structures et règles de paie configurables, multi-entreprise (isolation des données par client), notes de frais, onboarding/offboarding, SMS et WhatsApp.
- **Notre différenciation possible** ne passe pas par la copie d'Odoo. Elle repose sur quatre axes :
  1. **mobile d'abord et fonctionnement hors ligne** pour le terrain ;
  2. **paie et conformité localisées** pour le Togo, puis l'UEMOA ;
  3. **assistant RH conversationnel** branché sur les données autorisées ;
  4. **simplicité pour les PME sans service RH**.
- **Avant toute innovation**, il faut stabiliser l'existant : bugs d'affichage restants, tests automatisés côté backend quasi absents, multi-tenant absent.

> Validation humaine nécessaire : les éléments réglementaires (CNSS, IRPP, Code du travail togolais) doivent être vérifiés par un juriste ou un expert-comptable avant tout développement de paie.

---

## 2. Présentation d'Odoo et de son écosystème

Odoo est une suite ERP modulaire : comptabilité, ventes, stock, RH, site web, etc. Les applications RH partagent la base « Employés » et s'appuient les unes sur les autres. Par exemple, la paie consomme les présences, les congés et le planning.

### Éditions et offres (source : page tarifaire)

| Offre | Contenu | Remarques |
|---|---|---|
| **Community** | Open source (LGPL) | Contenu exact non vérifié dans cette analyse (la page `/page/editions` n'a pas été consultée) |
| **One App Free** | 1 application, utilisateurs illimités, Odoo Online | Gratuit, multi-société autorisé |
| **Standard** | Toutes les applications, Odoo Online | Facturé par utilisateur et par mois |
| **Custom** | Toutes les applications, Online / Odoo.sh / sur site, Studio, « Agentic AI », API externe | Facturé par utilisateur et par mois |
| **Light User** | Accès self-service (mes congés, mes dépenses, mes évaluations, mes présences, mes parrainages, mon planning, bulletins) | 2,50 € |

**Hors forfait (crédits IAP) :** SMS, autocomplétion de contacts, génération de leads, « IA pour scanner factures fournisseurs et dépenses ».

> Les montants précis en euros sont partiellement illisibles dans l'extraction de la page. **À vérifier** sur odoo.com avant tout argumentaire commercial.

### Niveau de preuve des affirmations sur Odoo

| Niveau | Utilisé ici |
|---|---|
| Observé dans une démonstration | **Non** : aucune instance de démonstration n'a été testée |
| Documenté (documentation officielle 18.0) | **Oui** : c'est la source principale |
| Code source public | Non consulté |
| Présenté commercialement | Oui (page tarifaire) |
| Non vérifiable | Signalé au cas par cas |

La documentation consultée **n'indique pas la répartition Community / Enterprise fonctionnalité par fonctionnalité**. Cette répartition est donc marquée « à vérifier » dans la suite.

---

## 3. Version et éditions étudiées

- Documentation : `odoo.com/documentation/18.0/applications/...`
- Pages lues : hr, employees, payroll, time_off, attendances, recruitment, appraisals, referrals, fleet, lunch, finance/expenses, pricing-plan.
- Page en échec : `productivity/ai.html` (HTTP 404).
- Pages non lues : Planning, Timesheets, Approvals, Frontdesk, Surveys, eLearning, page de comparaison des éditions. Les fonctionnalités qui en dépendent sont marquées « à vérifier ».

---

## 4. Inventaire des fonctionnalités RH d'Odoo (documentées)

| Domaine | Fonctionnalités documentées | Édition | Source |
|---|---|---|---|
| **A. Employés** | Dossiers centralisés, départements, compétences et CV (expériences, certifications), contrats, onboarding/offboarding, badges, équipements, rapport de rétention, présence déduite (pointage, connexion, e-mails, IP), télétravail par jour | Non précisée | employees |
| **B. Recrutement** | 6 étapes par défaut, modifiables ; statut coloré par candidat ; e-mail automatique à l'entrée dans une étape ; questionnaire d'entretien (Surveys) ; candidatures par formulaire en ligne, alias e-mail ou saisie ; configurateur de package salarial ; analyses par source, vélocité et équipe ; **OCR de CV (crédits IAP)** ; SMS (crédits) | Non précisée | recruitment |
| **C. Congés** | Types configurables (jours, demi-journées, heures), solde négatif plafonné, validation (aucune, responsable congés, manager, ou les deux), allocations, **plans d'acquisition** (fréquence, plafonds, report, expiration), jours fériés, jours obligatoires bloquants, calendrier d'équipe | Non précisée | time_off |
| **D. Présences** | Kiosque, saisie depuis le back-office, géolocalisation (IP et GPS), **heures supplémentaires** avec tolérances et validation, déduction des heures sup des congés, déconnexion automatique, détection d'anomalies (pas de sortie en 24 h, session de plus de 16 h) | Non précisée | attendances |
| **E. Temps / activités** | Feuilles de temps, planning | **À vérifier** (pages non lues) | — |
| **F. Contrats** | Créés dans Employés et détaillés dans la Paie (rémunération, horaire, avantages, structure salariale) | Non précisée | employees, payroll |
| **G. Paie** | Structures et règles salariales, *work entries* issues des présences, du planning ou des feuilles de temps, bulletins individuels ou par lot, virement SEPA ou chèque, écritures comptables, **localisations : AU, BE, EG, HK, JO, AE** | Non précisée (généralement Enterprise, **à vérifier**) | payroll |
| **H. Évaluations** | Planification automatique ou manuelle, auto-évaluation, demandes de feedback au manager, **360°**, objectifs, rapport d'évolution des compétences, modèles | Non précisée | appraisals |
| **I. Formations** | Certifications via compétences ; eLearning **à vérifier** | — | employees |
| **J. Dépenses** | Catégories, justificatifs (upload, e-mail), validation unitaire ou par lot, remboursement par la paie, refacturation analytique, **scan IA en crédits** | Non précisée | expenses, pricing |
| **K. Flotte / équipements** | Véhicules, conducteurs, entretiens, sinistres, analyse des coûts, alerte de fin de contrat ; équipements dans Employés | Non précisée | fleet, employees |
| **L. Portail employé** | Profil *Light User* : mes congés, dépenses, évaluations, présences, parrainages, planning, bulletins | Commercial | pricing |
| **M. Organisation** | Départements, hiérarchie ; organigramme **non mentionné** dans les pages lues | — | employees |
| **N. Rapports** | Analyses paie et effectifs, recrutement, rétention, compétences | Non précisée | hr, recruitment |
| **O. Automatisation / intégration** | E-mails automatiques par étape ; API externe (offre Custom) ; Studio (Custom) ; actions automatisées **à vérifier** | Commercial | pricing |
| **Autres** | Parrainage gamifié (points, récompenses, partage sur réseaux sociaux), repas (Lunch) | Non précisée | referrals, lunch |

### Phase 3 — IA et fonctions avancées chez Odoo

| Capacité | Statut |
|---|---|
| OCR de CV (nom, téléphone, e-mail) | **Documenté**, payant à l'usage (crédits IAP) |
| Scan IA des dépenses et factures fournisseurs | **Commercial**, payant (crédits IAP) |
| « Agentic AI » | **Mentionné commercialement** (offre Custom), **non documenté** dans les pages lues (page IA en 404) |
| Analyse prédictive RH (départs, absentéisme) | **Non trouvé** dans la documentation consultée |
| Assistant conversationnel RH | **Non trouvé** dans la documentation consultée |

Conclusion : l'IA d'Odoo dans le domaine RH, telle que documentée, est **ponctuelle (OCR) et facturée à l'usage**. Il n'y a pas d'aide à la décision RH documentée. C'est un espace de différenciation réel, à confirmer après lecture de la page `app/artificial-intelligence` d'Odoo.

---

## 5. Analyse technique et fonctionnelle de GRH-Mobile

### Architecture

| Couche | Technologie | Constat |
|---|---|---|
| Frontend | Flutter (web + Android), Riverpod, go_router, Dio, Hive (cache), fl_chart | Une seule base de code pour le web et le mobile |
| Backend | Spring Boot 3.3, Spring Security (JWT), JPA/Hibernate 6.5, Flyway | 22 contrôleurs, 18 services, 24 entités |
| Base | PostgreSQL ; 24 migrations Flyway (le schéma réel est en v27) | Schéma cohérent, contraintes de vérification présentes |
| Stockage de fichiers | Local (`uploads/`) + configuration AWS S3/CloudFront | Profil `application-aws.yml` |
| Sécurité | JWT, rôles (10), permissions dynamiques (`@acl.can`), audit (AOP), changement de mot de passe forcé, épinglage de certificat optionnel, déconnexion automatique | Socle solide |
| Tests | Flutter : 5 tests unitaires + 1 test d'intégration par rôle ; backend : 3 fichiers de test | **Couverture backend très faible** |
| IA | Aucune | — |
| Multi-entreprise | **Aucun** champ `entreprise_id` / tenant | Bloquant pour du SaaS multi-PME |
| SMS / WhatsApp | Aucun | — |

### Niveau de maturité par module

Les niveaux reprennent ceux de la mission. Ils s'appuient sur l'audit API par rôle, le test d'intégration Flutter sur Pixel 6 et la lecture du code du 1er novembre 2026.

| Module | Fonctionnalités réellement développées | Maturité |
|---|---|---|
| Authentification / rôles | Connexion JWT, 10 rôles, permissions modifiables, routes filtrées par rôle, mot de passe temporaire | **1 — Fonctionnel et vérifié** |
| Employés | CRUD, matricule, service, département, poste, manager, documents, compétences, annuaire, « mon équipe » | **2 — Partiellement vérifié** (débordement d'affichage restant pour le rôle RH) |
| Départements / postes | CRUD, organigramme (`/departements/organigramme`), fourchettes salariales | **2** (données créées par seed, CRUD non testé par l'interface) |
| Présences | Pointage, scan QR, géolocalisation (lat/long), signalement et justification d'absence | **2** — pas d'heures supplémentaires ni de kiosque |
| Congés | Demande, approbation, refus, solde, types (annuel, maladie, sans solde…) | **2** — pas de plan d'acquisition ni de jours fériés |
| Paie | Calcul mensuel (brut, cotisations, impôts, indemnités, net), validation, bulletin PDF, export CSV | **3 — Partiellement développé** : taux fixes, sans règles configurables ni conformité locale vérifiée |
| Contrats | CRUD, statut, contrats arrivant à expiration | **2** |
| Recrutement | Offres (publiques et internes), candidatures avec CV, entretiens, embauche (candidat → employé) | **2** — étapes non configurables, pas d'e-mail automatique |
| Formations | Catalogue, inscription, participation | **2** |
| Évaluations | Création, soumission, validation, notes par axe, objectifs | **2** — débordement d'affichage restant ; pas de 360° |
| Rapports | Tableaux de bord (synthèse, enrichi), export, génération | **2** (l'export n'est pas testé) |
| Notifications | In-app, lecture, tout marquer comme lu | **2** — pas de push, SMS ni e-mail vérifié |
| Audit | Journal des actions avec filtres | **1** (500 corrigé le 1er novembre 2026) |
| Portail employé | Espace dédié : profil, présences, congés, bulletins, documents, objectifs, évaluations, QR | **1** (test d'intégration vert) |
| Notes de frais, flotte, onboarding, planning, feuilles de temps | — | **6 — Non implémenté** |

---

## 6. Tableau comparatif

| Domaine | Fonctionnalité Odoo | Chez nous | Maturité | Différence | Recommandation |
|---|---|---|---|---|---|
| Employés | Dossier complet, CV et compétences | Présent | 2 | Pas de parcours (historique de postes) | Ajouter l'historique de carrière |
| Employés | Onboarding / offboarding | **Absent** | 6 | — | Checklists d'arrivée et de départ (lot 1) |
| Employés | Équipements | **Absent** | 6 | — | Inventaire simple du matériel attribué (lot 1, priorité basse) |
| Organisation | Organigramme | Présent (API) | 2 | Odoo ne le mentionne pas dans les pages lues | Mettre en avant à l'écran : avantage potentiel |
| Recrutement | Étapes configurables | Statuts fixes | Moins avancé | Pas de pipeline personnalisable | Étapes paramétrables par entreprise |
| Recrutement | E-mail auto par étape | **Absent** | 6 | — | Modèles d'e-mail et de SMS (lot 1) |
| Recrutement | OCR de CV | **Absent** | 6 | Odoo : payant à l'usage | Extraction de CV intégrée (lot 3) |
| Recrutement | Candidat → employé | **Présent** | 2 | Odoo ne décrit pas de conversion dans les pages lues | Conserver |
| Congés | Types configurables | Types fixes (enum) | Moins avancé | — | Rendre les types paramétrables |
| Congés | Plans d'acquisition | **Absent** | 6 | Clé pour la conformité | Acquisition mensuelle (lot 1) |
| Congés | Jours fériés, calendrier d'équipe | **Absent** | 6 | — | Calendrier des jours fériés par pays (lot 1) |
| Présences | QR / géolocalisation | **Présent** | 2 | Comparable | Conserver |
| Présences | Heures supplémentaires et tolérances | **Absent** | 6 | — | Lot 1 |
| Présences | Détection d'anomalies (sortie oubliée) | **Absent** | 6 | — | Lot 2 (règles simples), puis lot 3 |
| Présences | Kiosque partagé | **Absent** | 6 | — | Mode kiosque sur tablette (lot 2) |
| Paie | Structures et règles salariales | Calcul à taux fixes | 3 | Écart majeur | Moteur de règles (lot 1) |
| Paie | Localisation pays | **Absente** | 6 | Odoo : aucun pays UEMOA documenté | **Togo d'abord** : opportunité forte |
| Paie | Paiement / écriture comptable | Export CSV | Moins avancé | — | Export comptable et mobile money (lot 2) |
| Contrats | Alertes d'expiration | **Présent** | 2 | Comparable | Ajouter un rappel automatique |
| Évaluations | Cycle complet, objectifs | Présent | 2 | Pas de 360°, pas de planification automatique | Lot 2 |
| Formations | Catalogue et suivi | Présent | 2 | eLearning Odoo à vérifier | Recommandations de formation (lot 3) |
| Dépenses | Notes de frais avec justificatifs | **Absent** | 6 | — | Lot 1 (forte demande des PME terrain) |
| Flotte | Véhicules | **Absent** | 6 | Hors cœur de cible | Non prioritaire |
| Portail | Self-service employé | **Présent** | 1 | Comparable, mobile natif | Conserver et enrichir |
| Rapports | Analyses RH | Présent | 2 | — | Indicateurs PME (lot 3) |
| Automatisation | Actions automatisées, Studio | **Absent** | 6 | — | Moteur de rappels et d'échéances (lot 3) |
| Intégration | API externe | API REST interne | 2 | Pas de documentation publique ni de clé API | OpenAPI + clés API (lot 5) |
| Multi-société | Oui | **Absent** | 6 | Bloquant pour le SaaS | **Lot 5, à anticiper dès le lot 1** |
| IA | OCR (payant) | Aucune | 6 | — | Lot 3 |
| Audit | Historique (chatter) | **Journal d'audit dédié** | 1 | Comparable | Conserver |

---

## 7. Fonctionnalités Odoo absentes chez nous (catégorie 1)

| Fonctionnalité | Intérêt pour une PME | Difficulté |
|---|---|---|
| Plans d'acquisition de congés et jours fériés | Conformité légale, fin des calculs à la main | Moyenne |
| Heures supplémentaires | Paie juste, réduction des litiges | Moyenne |
| Moteur de règles de paie | Prérequis pour toute localisation | **Élevée** |
| Notes de frais | Employés terrain, remboursements | Moyenne |
| Onboarding / offboarding | Rien d'oublié à l'arrivée ou au départ | Faible |
| Étapes de recrutement et e-mails automatiques | Gain de temps | Faible à moyenne |
| Multi-entreprise | Indispensable pour vendre à plusieurs PME | **Élevée** (impacte toutes les tables) |
| Notifications SMS / WhatsApp | Usage réel au Togo | Faible à moyenne (fournisseur tiers) |

## 8. Fonctionnalités à améliorer (catégorie 2)

1. **Paie** : sortir les taux codés en dur (4 %, 8 %, 5 % dans le seed) vers des règles configurables par pays.
2. **Congés** : types paramétrables et circuit de validation à deux niveaux.
3. **Évaluations** : planification automatique, 360°, et correction du débordement d'affichage.
4. **Recrutement** : pipeline configurable.
5. **Notifications** : canaux push, e-mail et SMS.
6. **Qualité** : tests backend (3 fichiers seulement), corrections non commitées, erreurs d'affichage RH sur la liste des employés.
7. **Données de démo** : intégrer le jeu de données dans `DataSeeder` ou une migration de démo, plutôt que d'utiliser des scripts SQL manuels.

## 9. Fonctionnalités déjà satisfaisantes (catégorie 3)

- Authentification, rôles et permissions dynamiques
- Journal d'audit
- Portail employé mobile (test vert)
- Pointage par QR code et géolocalisation
- Conversion candidat → employé
- Alertes de contrats arrivant à expiration
- Organigramme (côté API)

## 10. Avantages potentiels (catégorie 4)

| Avantage | Pourquoi c'est différenciant | Vérifiable ? |
|---|---|---|
| Application mobile native web + Android | Odoo est d'abord web ; nous sommes pensés mobile | Démontrable |
| QR de pointage par employé | Simple, sans matériel dédié | Démontrable |
| Contexte togolais | Odoo n'a aucune paie UEMOA documentée | Oui, si nous livrons la localisation |
| Simplicité (pas un ERP complet) | Moins de configuration pour une PME de 10 à 50 personnes | À mesurer (temps de prise en main) |

---

## 11. Innovations proposées

> Principe : aucune décision RH sensible (embauche, sanction, licenciement, salaire) n'est prise par l'IA. L'IA propose, un humain valide, et chaque réponse cite ses données.

| # | Innovation | Problème résolu | Utilisateurs | Technologies | Données | Sécurité | Difficulté | Coût | Différenciation |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Assistant RH conversationnel** (« Quels contrats expirent ce mois ? ») | Le dirigeant n'a pas le temps de chercher dans les écrans | Direction, RH | LLM (API Claude) + appel d'outils sur nos endpoints existants (pas d'accès SQL direct) | API actuelles | Filtrage par rôle hérité du JWT, journal d'audit des questions | Moyenne | Moyen (coût par requête) | **Forte** |
| 2 | **Assistant employé FAQ** (« Combien de congés me reste-t-il ? ») | Questions répétitives au RH | Employés | Même socle, limité aux endpoints `/me` | Données personnelles | Strictement limité à l'employé connecté | Faible à moyenne | Faible | Forte |
| 3 | **Détection d'anomalies de présence** | Oublis de pointage, fraudes, retards répétés | RH, managers | Règles d'abord, statistiques ensuite | Présences | Alerte seulement, sans sanction automatique | Faible | Faible | Moyenne |
| 4 | **Prévision de la masse salariale** | Anticiper la trésorerie | Direction | Projection simple (contrats, embauches prévues) | Paie, contrats | — | Faible à moyenne | Faible | Moyenne |
| 5 | **Intelligence documentaire** (lecture de CNI, diplômes, contrats ; dates d'expiration ; pièces manquantes) | Dossiers incomplets | RH | OCR + LLM vision | Documents | Données sensibles : chiffrement, consentement | Moyenne | Moyen | Forte (Odoo : CV seulement, payant) |
| 6 | **Générateur de documents RH** (attestation de travail, contrat, certificat) | Rédaction manuelle | RH | Modèles + LLM pour la rédaction, validation humaine | Employés, contrats | Relecture obligatoire | Faible | Faible | Moyenne |
| 7 | **Recommandation de formations par écart de compétences** | Formations mal ciblées | RH, employés | Matching compétences du poste ↔ compétences de l'employé | Compétences, postes | Suggestion uniquement | Moyenne | Faible | Moyenne |
| 8 | **Indicateur de risque de départ** | Départs non anticipés | RH | Score explicable (ancienneté, absences, évaluations) | Historique sur au moins 12 mois | **Risque de biais élevé** : score visible du RH seulement, explicable, jamais utilisé seul | Élevée | Moyen | Forte, mais délicate |
| 9 | **Mode hors ligne + synchronisation** | Connexion instable sur le terrain | Employés terrain | Hive (déjà présent) + file de synchronisation | Pointages, demandes | Horodatage signé pour éviter la fraude | Moyenne | Moyen | **Forte** pour le contexte africain |
| 10 | **Paie mobile money** (export pour T-Money / Flooz) | Salariés non bancarisés | RH, comptable | Fichier de paiement en masse | Paie | Validation à deux personnes | Moyenne | Faible à moyen | **Forte** (absent d'Odoo documenté) |
| 11 | **Notifications SMS / WhatsApp** | Les e-mails ne sont pas lus | Tous | Fournisseur SMS local ou API WhatsApp Business | Téléphones | Consentement | Faible | Coût par message | Moyenne |
| 12 | **Import Excel guidé** | Données existantes sur Excel | RH | Assistant d'import avec contrôle de cohérence | Fichiers Excel | — | Faible | Faible | Forte pour l'adoption |

---

## 12. Adaptations aux réalités des PME

| Contrainte | Réponse proposée |
|---|---|
| Pas de service RH | Assistant conversationnel, valeurs par défaut prêtes à l'emploi, import Excel |
| Plusieurs sites | Champ « établissement » sur l'employé et le pointage ; rapports par site |
| Employés terrain | QR (existant) + hors ligne + géolocalisation (existante) |
| Internet instable | Cache Hive étendu, file de synchronisation |
| Budget limité | Prix par entreprise plutôt que par utilisateur (à étudier), pas de crédits IA cachés |
| Smartphones | Application Android déjà disponible ; optimiser pour l'entrée de gamme |
| Papier / Excel | Import guidé, génération de documents |
| Localisation | Français par défaut ; jours fériés, règles de congés et paie **par pays**, à valider juridiquement (Togo d'abord) |
| Protection des données | Loi togolaise sur la protection des données personnelles à vérifier ; hébergement, consentement, droit d'accès |

---

## 13. Positionnement face à Odoo

**Proposition de valeur :** *« La plateforme RH mobile pensée pour les PME d'Afrique de l'Ouest : paie locale, pointage terrain même hors ligne, et un assistant qui répond à vos questions RH. »*

| Question | Réponse honnête aujourd'hui |
|---|---|
| Pourquoi nous plutôt qu'Odoo ? | Localisation togolaise et UEMOA (si livrée), mobile d'abord, simplicité, IA incluse |
| Ce que nous faisons mieux (démontrable) | Rien n'est encore prouvé par une comparaison chronométrée. Il faut mesurer avant d'affirmer. |
| Fonctions comparables | Portail employé, pointage géolocalisé, contrats arrivant à expiration, audit |
| Fonctions signature visées | Paie Togo + mobile money, hors ligne, assistant RH |

### Indicateurs de progression

- Temps de mise en route d'une PME de 20 salariés (cible : moins d'une heure)
- Couverture fonctionnelle de la grille du §6 (cible : 80 % au statut « présent »)
- Bulletins de paie conformes, validés par un expert-comptable (cible : 100 % sur un panel)
- Taux de pointages hors ligne synchronisés sans perte
- Questions de l'assistant avec réponse correcte et sourcée (cible : 90 %)
- Couverture des tests backend

---

## 14. Feuille de route par lots

```
Lot 2 (stabilisation) ──► Lot 1 (mise à niveau) ──► Lot 3 (IA / innovation)
        │                         │
        └─────────► Lot 5 (multi-tenant : à concevoir tôt) ◄──┘
Lot 4 (performance / sécurité / UX) : en continu
```

> Ordre recommandé : **lot 2 d'abord**, car on ne construit pas sur des bugs connus. La conception multi-tenant (lot 5) doit être décidée **avant** le lot 1, parce qu'elle touche toutes les tables.

| Lot | Objectifs | Fonctionnalités | Fichiers / modules concernés | Risques | Difficulté | Tests et critères d'acceptation |
|---|---|---|---|---|---|---|
| **2 — Perfectionnement** | Stabiliser | Correction des bugs d'affichage (Évaluations, Employés RH), commit des correctifs, jeu de démo dans `DataSeeder`, tests backend des services | `evaluations_screen.dart`, `employee_list_screen.dart`, `DataSeeder.java`, `backend/src/test` | Faible | Faible | Test d'intégration vert pour les 4 rôles ; au moins 60 % de couverture des services |
| **1 — Mise à niveau** | Combler les manques | Plans d'acquisition et jours fériés, heures supplémentaires, moteur de règles de paie, notes de frais, onboarding, étapes de recrutement | `CongeService`, `PresenceService`, `PaieService`, nouvelles entités `RegleSalariale`, `NoteFrais`, `PlanAcquisition` + migrations Flyway | Paie : erreurs légales | Élevée | Cas de paie validés par un expert-comptable ; tests unitaires des règles |
| **3 — IA et innovation** | Différencier | Assistant RH (outils = nos endpoints), FAQ employé, anomalies de présence, générateur de documents, hors ligne, mobile money, SMS | Nouveau module `assistant` (backend), écran de chat Flutter, `cache_service.dart` | Coût de l'IA, confidentialité, biais | Moyenne | Réponses sourcées, refus hors périmètre du rôle, journal d'audit |
| **4 — Perf / sécu / UX** | Qualité | Pagination, index, chiffrement des documents, accessibilité, appareils d'entrée de gamme | Transverse | — | Moyenne | Temps de réponse inférieur à 500 ms (p95), audit OWASP |
| **5 — Commercialisation** | SaaS | Multi-entreprise (`entreprise_id` + filtre), configuration par entreprise, abonnements, sauvegardes, supervision, documentation, support | Toutes les entités, `SecurityConfig`, migrations | **Fuite de données entre clients** | Élevée | Tests d'isolation entre tenants obligatoires |

---

## 15. Priorisation (valeur / complexité)

| Priorité | Intervention | Valeur | Complexité |
|---|---|---|---|
| P0 | Stabilisation (lot 2) | Haute | Faible |
| P0 | Décision d'architecture multi-tenant | Haute | Moyenne (conception) |
| P1 | Congés : acquisition + jours fériés | Haute | Moyenne |
| P1 | Moteur de paie + localisation Togo | Très haute | Élevée |
| P1 | Heures supplémentaires | Haute | Moyenne |
| P2 | Assistant RH conversationnel | Haute (différenciation) | Moyenne |
| P2 | Hors ligne terrain | Haute | Moyenne |
| P2 | Notes de frais | Moyenne | Moyenne |
| P3 | Intelligence documentaire, risque de départ | Moyenne | Élevée |
| P3 | Flotte, repas | Faible | — |

## 16. Risques et dépendances

- **Juridique** : règles de paie et de congés à valider par pays. Si elles sont fausses, la promesse de valeur s'effondre.
- **Multi-tenant tardif** : coût de refonte élevé si on attend.
- **IA** : coût par requête, hallucinations (d'où les réponses via appel d'outils et citations), confidentialité des données RH envoyées à un fournisseur (contrat de traitement nécessaire).
- **Biais** : tout score prédictif sur les personnes doit être explicable et supervisé.
- **Odoo** : informations issues de la documentation, pas d'une démonstration. Les éditions et les prix sont à confirmer.
- **Licences** : Odoo Community est sous LGPL et Enterprise sous licence propriétaire. **Aucune réutilisation de code** n'est proposée ; on s'inspire seulement des fonctionnalités.

## 17. Recommandations stratégiques finales

1. **Stabiliser avant d'innover** : finir le lot 2, commiter les correctifs, viser un test d'intégration vert pour les 4 rôles.
2. **Décider maintenant de l'architecture multi-entreprise.**
3. **Faire de la paie togolaise la fonctionnalité signature**, validée par un expert-comptable.
4. **Ajouter les plans d'acquisition de congés et les jours fériés.**
5. **Ajouter les heures supplémentaires et la détection d'anomalies de présence.**
6. **Construire l'assistant RH sur nos API existantes** (appel d'outils, réponses sourcées, droits par rôle).
7. **Mode hors ligne pour le terrain**, en s'appuyant sur Hive, déjà présent.
8. **Paiement des salaires par mobile money et notifications SMS / WhatsApp.**
9. **Import Excel guidé** pour réduire la barrière d'adoption.
10. **Mesurer avant d'affirmer** : comparer chronomètre en main des parcours réels sur Odoo et sur notre application avant toute communication « mieux qu'Odoo ».

## 18. Points nécessitant une validation humaine

- Répartition Community / Enterprise par fonctionnalité Odoo
- Prix exacts d'Odoo
- Contenu de la page IA d'Odoo et de « Agentic AI »
- Règles CNSS, IRPP et Code du travail togolais
- Choix du fournisseur d'IA et hébergement des données
- Choix des fournisseurs SMS et mobile money

## 19. Sources consultées (1er novembre 2026)

- https://www.odoo.com/documentation/18.0/applications/hr.html
- https://www.odoo.com/documentation/18.0/applications/hr/employees.html
- https://www.odoo.com/documentation/18.0/applications/hr/payroll.html
- https://www.odoo.com/documentation/18.0/applications/hr/time_off.html
- https://www.odoo.com/documentation/18.0/applications/hr/attendances.html
- https://www.odoo.com/documentation/18.0/applications/hr/recruitment.html
- https://www.odoo.com/documentation/18.0/applications/hr/appraisals.html
- https://www.odoo.com/documentation/18.0/applications/hr/referrals.html
- https://www.odoo.com/documentation/18.0/applications/hr/fleet.html
- https://www.odoo.com/documentation/18.0/applications/hr/lunch.html
- https://www.odoo.com/documentation/18.0/applications/finance/expenses.html
- https://www.odoo.com/pricing-plan
- Échec : https://www.odoo.com/documentation/18.0/applications/productivity/ai.html (HTTP 404)
- Code source GRH-Mobile (backend `com.grhmobile`, frontend `lib/`), audit API par rôle et test d'intégration Flutter du 1er novembre 2026
