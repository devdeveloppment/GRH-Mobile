# grh_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# 🌟 Aperçu des Fonctionnalités de GRH-Mobile

GRH-Mobile est un SIRH (Système d'Information Ressources Humaines) de pointe, conçu pour une gestion fluide, centralisée, et en temps-réel du cycle de vie des collaborateurs. L'architecture est totalement dynamique (Spring Boot + Flutter).

## 🛡️ 1. Cœur d'Administration & Sécurité

- **Authentification & Session :** Système sécurisé avec péremption automatique.
- **Droits d'accès Granulaires (RBAC) :** 10 rôles dynamiques _(du Super Admin à l'Employé)_ avec interfaces intelligentes adaptées au niveau de permission.
- **Audit Logging :** Traçabilité à 100%. Toute création, mise à jour ou suppression est enregistrée avec des horodatages précis par utilisateur.

## 📊 2. Pilotage & Décisionnel

- **Tableaux de bords Temp-Réel :** Les métriques globales _(Masse salariale active, absences, départs imminents)_ s'auto-synchronisent à travers tout le système après la moindre modification dans la base de données.
- **Rapports & Exports :** Génération de statistiques (PDF/Excel) permettant à la direction de visualiser l'évolution des effectifs.

## 👥 3. Gestion Administrative (Core HR)

- **Base Employés à 360° :** Suivi centralisé (Infos, Départements, Rôles, Documents).
- **Organisation :** Structuration en arbre par _Départements_ et par _Postes_ permettant des liaisons hiérarchiques (Manager → Employé).
- **Contrats & Carrières :** Création de CDD/CDI avec alertes préventives (J-30) générées sur le Dashboard à l'approche de la péremption d'un contrat.

## ⏰ 4. Workflow : Présences, Congés & Paie

- **Pointage par QR Code Intégré :** Fluidifie l'arrivée des employés grâce aux scans mobiles depuis l'application.
- **Validation des Congés (Circuit d'approbation) :** Employé demande ➔ Manager reçoit l'alerte ➔ Validation ou Refus instantanés.
- **Génération des Paies :** Calcul automatique complexe (Charges, Déductions CNSS, Impôts) et mise à disposition mensuelle dématérialisée de la fiche de paie en format PDF pour le collaborateur.

## 🚀 5. Gestion des Talents (ATS)

- **Recrutement :** Diffusion d'offres d'emploi, pipeline de suivi des CVs (En attente, Entretien, Décision).
- **Formation & Évaluation :** Création de sessions de coaching avec invitations automatiques; évaluations semestrielles avec feedbacks pour suivre la performance d'équipe.
