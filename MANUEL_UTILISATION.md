# Manuel d'utilisation — GRH-Mobile

**Version** : 1.0.0  
**Dernière mise à jour** : Mai 2026

---

## Table des matières

1. [Présentation de l'application](#1-présentation-de-lapplication)
2. [Connexion et déconnexion](#2-connexion-et-déconnexion)
3. [Rôles et accès](#3-rôles-et-accès)
4. [Navigation générale](#4-navigation-générale)
5. [Module Dashboard](#5-module-dashboard)
6. [Module Employés](#6-module-employés)
7. [Module Départements](#7-module-départements)
8. [Module Postes](#8-module-postes)
9. [Module Présences et QR Code](#9-module-présences-et-qr-code)
10. [Module Congés](#10-module-congés)
11. [Module Contrats](#11-module-contrats)
12. [Module Paie](#12-module-paie)
13. [Module Recrutement](#13-module-recrutement)
14. [Module Formations](#14-module-formations)
15. [Module Évaluations](#15-module-évaluations)
16. [Module Rapports](#16-module-rapports)
17. [Module Notifications](#17-module-notifications)
18. [Profil utilisateur](#18-profil-utilisateur)
19. [Administration système](#19-administration-système)
20. [Espace employé](#20-espace-employé)

---

## 1. Présentation de l'application

**GRH-Mobile** est un Système d'Information des Ressources Humaines (SIRH) multi-plateforme développé avec Flutter. Il permet la gestion complète du personnel d'une organisation : recrutement, présences, congés, contrats, paie, évaluations et formations.

**Plateformes supportées** : Linux Desktop, Android, iOS, Web  
**Langue** : Français (Togo)

---

## 2. Connexion et déconnexion

### Connexion

1. Lancez l'application.
2. Sur l'écran de connexion, saisissez votre **adresse e-mail** et votre **mot de passe**.
3. Cliquez sur **Se connecter**.
4. L'application vous redirige automatiquement vers le dashboard correspondant à votre rôle.

> **Compte administrateur par défaut**  
> E-mail : `admin@grh-mobile.com`  
> Mot de passe : `Admin@12345`  
> Changez ce mot de passe dès la première connexion.

### Session et déconnexion automatique

- La session expire après **8 heures** d'utilisation.
- En cas d'**inactivité de 30 minutes**, la déconnexion est automatique.
- Pour vous déconnecter manuellement, cliquez sur l'icône de déconnexion dans la barre latérale (en bas à gauche).

---

## 3. Rôles et accès

L'application utilise un système de rôles pour contrôler l'accès aux fonctionnalités.

| Rôle | Description | Modules accessibles |
|------|-------------|---------------------|
| **SUPER_ADMIN** | Accès total multi-instance | Tous les modules |
| **ADMIN** | Administrateur de l'instance | Tous les modules + gestion utilisateurs |
| **HR_ADMIN** | RH senior | Tous les modules RH |
| **RH_MANAGER** | RH opérationnel | Employés, Présences, Congés, Contrats, Recrutement, Formations, Évaluations, Paie |
| **PAYROLL_OFFICER** | Gestionnaire paie | Paie, Contrats, Rapports |
| **MANAGER** | Manager d'équipe | Équipe, Présences, Congés, Évaluations, Formations |
| **RECRUITER** | Recruteur | Recrutement |
| **TRAINER** | Formateur | Formations |
| **EMPLOYEE** | Employé standard | Espace personnel (profil, présences, congés, bulletin) |
| **DIRECTION** | Direction | Dashboards de pilotage, Rapports, Évaluations |

---

## 4. Navigation générale

### Barre latérale (Sidebar)

- Sur **grand écran (≥ 1024 px)** : la barre latérale est toujours visible à gauche.
- Sur **petit écran** : appuyez sur l'icône ☰ dans la barre du haut pour ouvrir le menu.

### En-tête (AppBar)

- Affiche le nom de la page courante.
- Affiche votre nom d'utilisateur connecté.
- Donne accès aux notifications et au profil.

---

## 5. Module Dashboard

Le dashboard s'adapte automatiquement à votre rôle.

### Dashboard RH / RH Manager

Affiche les indicateurs clés :
- Nombre total d'employés actifs
- Présences du jour
- Congés en attente
- Contrats expirant bientôt

### Dashboard Admin / Super Admin

Console d'administration avec :
- Vue d'ensemble de tous les modules
- Statistiques globales
- Accès rapide aux fonctions d'administration

### Dashboard Direction

Tableaux de bord de pilotage stratégique :
- Graphiques d'évolution des effectifs
- Indicateurs de performance RH
- Rapports synthétiques

### Dashboard Manager

Vue de l'équipe :
- Liste des membres de l'équipe
- Présences et absences
- Évaluations en cours

---

## 6. Module Employés

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER

### Liste des employés

- Affiche tous les employés avec : photo, nom, poste, service, statut, présence du jour.
- **Recherche** : saisissez un nom, matricule, e-mail ou poste dans la barre de recherche.
- **Filtres** : filtrez par statut (Actif, Archivé) ou par service.
- **Pagination** : navigation par pages de 20 employés.
- Cliquez sur un employé pour accéder à son profil détaillé.

### Profil employé

Le profil contient 6 onglets :

| Onglet | Contenu |
|--------|---------|
| **Informations** | Données personnelles et professionnelles, compétences, documents |
| **Contrat** | Type de contrat, dates, salaire |
| **Paie** | Historique des bulletins de salaire |
| **Compétences** | Niveaux de compétences |
| **Documents** | Documents RH (CV, contrat, diplômes, CIN) |
| **Historique** | Présences et congés |

### Créer un employé

1. Cliquez sur le bouton **+** (Nouvel employé).
2. Remplissez le formulaire : informations personnelles, poste, service, type de contrat, salaire.
3. Validez. Un compte utilisateur est automatiquement créé avec le mot de passe temporaire `ChangeMe@123`.

### Modifier / Archiver un employé

- Cliquez sur l'icône **crayon** dans la ligne de l'employé pour modifier.
- Cliquez sur l'icône **archive** pour archiver (l'employé passe au statut ARCHIVE et son compte est désactivé).

---

## 7. Module Départements

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER

- Affiche la liste des départements avec leur responsable et le nombre d'employés.
- **Créer** un département : bouton + → renseigner le nom, description et responsable.
- **Modifier** : cliquer sur l'icône crayon.
- **Supprimer** : cliquer sur l'icône corbeille (confirmation demandée).

---

## 8. Module Postes

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER

- Liste des postes de l'organisation avec leur département associé.
- Chaque poste indique : intitulé, département, niveau de compétence requis.
- **Créer / Modifier / Supprimer** un poste via les icônes d'action.

---

## 9. Module Présences et QR Code

### Vue d'ensemble des présences

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER, MANAGER

- Tableau de bord des présences du jour : nombre de présents, absents, en retard.
- Historique des présences par employé.
- Filtrage par date et par statut.

### Pointage par QR Code

**Pour les managers / RH** — Scanner le QR d'un employé :
1. Accédez à **QR Scanner** dans le menu.
2. Pointez la caméra sur le QR Code de l'employé.
3. La présence est enregistrée automatiquement.

**Pour l'employé** — Afficher son QR Code :
1. Accédez à **Mon QR Code** dans l'espace employé.
2. Présentez le QR Code au scanner.

---

## 10. Module Congés

### Consulter les congés

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER, MANAGER

- Liste de toutes les demandes de congé avec statut (EN_ATTENTE, APPROUVÉ, REFUSÉ).
- Filtrage par statut et par période.

### Demander un congé (Employé)

1. Accédez à l'espace employé → **Demande de congé**.
2. Renseignez : type de congé, date de début, date de fin, motif.
3. Soumettez. Le RH reçoit une notification.

### Approuver / Refuser un congé (RH / Manager)

1. Dans la liste des congés, cliquez sur la demande.
2. Choisissez **Approuver** ou **Refuser**.
3. L'employé reçoit une notification du résultat.

---

## 11. Module Contrats

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER, PAYROLL_OFFICER

### Contrats expirant bientôt

- La page principale affiche les **contrats expirant dans les 30 prochains jours**.
- Chaque carte indique : nom de l'employé, type de contrat, date d'expiration, poste, statut.

### Gérer les contrats d'un employé

1. Accédez au profil d'un employé → onglet **Contrat**.
2. Créez un nouveau contrat via **+** : type (CDI, CDD, Freelance…), dates, salaire brut, poste, département.
3. Modifiez le statut d'un contrat existant : ACTIF → EXPIRÉ ou RÉSILIÉ.

---

## 12. Module Paie

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER, PAYROLL_OFFICER

### Calcul de la paie

1. Sélectionnez la période (mois/année).
2. Cliquez sur **Calculer la paie** pour générer les bulletins.
3. Vérifiez les montants calculés (salaire brut, cotisations, impôts, indemnités, salaire net).
4. Validez les bulletins.

### Bulletins de salaire

- Les bulletins sont téléchargeables au format PDF.
- Chaque bulletin affiche : salaire brut, cotisations CNSS, impôts, indemnités, salaire net.

### Vue employé

L'employé peut consulter ses bulletins de salaire depuis son espace personnel → onglet **Bulletin**.

---

## 13. Module Recrutement

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER, RECRUITER

### Offres d'emploi

- Créez des offres avec : titre, description, département, type de contrat, date limite.
- Activez/désactivez une offre.

### Candidatures

- Consultez les candidatures reçues pour chaque offre.
- Changez le statut d'une candidature : EN_ATTENTE → EN_COURS → RETENU / REFUSÉ.
- Les candidats peuvent postuler via le lien public `/apply`.

---

## 14. Module Formations

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER, MANAGER, TRAINER

- Liste des formations planifiées avec : titre, description, formateur, date, durée, participants.
- **Créer** une formation : renseignez les informations et les participants.
- **Modifier / Annuler** une formation existante.
- Les employés inscrits reçoivent une notification.

---

## 15. Module Évaluations

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER, MANAGER, DIRECTION

- Liste des évaluations par période (annuelle, semestrielle, etc.).
- **Créer** une évaluation : sélectionnez l'employé, la période, la note (0–10) et les commentaires.
- L'employé peut consulter ses évaluations depuis son espace personnel → onglet **Mes évaluations**.

---

## 16. Module Rapports

> Accessible aux rôles : ADMIN, HR_ADMIN, RH_MANAGER, PAYROLL_OFFICER, DIRECTION

- Génération de rapports sur :
  - Effectifs par département / service
  - Présences et absences sur une période
  - Masse salariale
  - Congés pris vs restants
- Export possible en PDF ou Excel selon le type de rapport.

---

## 17. Module Notifications

- Toutes les notifications du système apparaissent ici.
- Badge rouge indiquant le nombre de notifications non lues.
- Actions : **Tout marquer comme lu**, ou cliquer sur une notification pour accéder à la page concernée.

Types de notifications :
- Nouvelle demande de congé
- Contrat créé ou modifié
- Résultat d'une candidature
- Formation planifiée
- Bulletin de paie disponible

---

## 18. Profil utilisateur

Accès : icône profil dans la barre latérale (bas gauche) ou menu.

### Informations affichées

- Nom complet
- Adresse e-mail
- Rôle dans le système

### Modifier la photo de profil

1. Cliquez sur la photo ou l'icône appareil photo.
2. Choisissez la source : **Caméra** ou **Galerie**.
3. La photo est uploadée et mise à jour immédiatement.

### Supprimer la photo

Cliquez sur **Supprimer la photo** (visible si une photo est déjà définie).

---

## 19. Administration système

> Accessible aux rôles : SUPER_ADMIN, ADMIN

### Gestion des utilisateurs (`/admin/users`)

- Liste de tous les comptes utilisateurs.
- **Créer** un utilisateur : nom, e-mail, rôle, mot de passe temporaire.
- **Activer / Désactiver** un compte.
- **Modifier le rôle** d'un utilisateur.

### Gestion des rôles (`/admin/roles`)

- Vue d'ensemble des rôles disponibles et leurs permissions.

### Paramètres (`/admin/settings`)

- Configuration générale de l'instance.
- Gestion des paramètres de sécurité (durée de session, politique de mot de passe).

### Journal d'audit (`/admin/audit`)

> Accessible aux rôles : SUPER_ADMIN, ADMIN, HR_ADMIN

- Historique complet de toutes les actions effectuées dans le système.
- Informations : utilisateur, action, entité modifiée, date et heure.
- Filtrable par utilisateur, type d'action et période.

---

## 20. Espace employé

Les employés (rôle EMPLOYEE) accèdent à un espace simplifié affichant :

- **Mon profil** : informations personnelles et professionnelles
- **Mes présences** : historique des pointages
- **Mes congés** : demandes en cours et historique
- **Mon bulletin** : fiches de paie mensuelles (téléchargeables en PDF)
- **Mon QR Code** : code personnel pour le pointage
- **Mes objectifs** : objectifs fixés par le manager
- **Mes évaluations** : résultats des évaluations périodiques
- **Notifications** : alertes et informations

---

*Pour toute question technique, contactez l'administrateur système.*
