# Intégrations SMS et paiement mobile money

Public visé : décideur et intégrateur. État au 02/11/2026 : **architecture prête, aucun fournisseur
choisi, aucun compte, aucune clé, aucun contrat. Envois et paiements désactivés.**

## 1. Principes non négociables

- Un SMS n'est jamais présenté comme envoyé sans accusé du fournisseur (`ENVOYE`) ; sinon `NON_ENVOYE`.
- Un paiement n'est `REUSSI` que sur notification **serveur à serveur** à signature vérifiée **et** montant
  identique au montant attendu. Le retour du navigateur ou de l'application mobile ne compte jamais.
- Pas de simulation de paiement réussi hors des tests automatisés (fournisseur fictif défini uniquement
  dans `src/test`).

## 2. Architecture en place (backend)

| Élément | Rôle |
|---|---|
| `integrations/sms/FournisseurSms` | Interface d'envoi (SMS ou WhatsApp) |
| `SmsDesactive` | Implémentation par défaut : n'envoie rien, renvoie `NON_ENVOYE` |
| `integrations/paiement/FournisseurPaiement` | Interface : initier, vérifier la signature, lire la notification |
| `PaiementService` | Référence unique `GRH-<uuid>`, clé d'idempotence obligatoire, expiration à 30 min, finalisation unique, contrôle du montant, journal des notifications |
| `POST /api/plateforme/paiements` (SUPER_ADMIN) | Créer une transaction (`Idempotency-Key` requis) — 503 tant que rien n'est configuré |
| `POST /api/paiements/notifications/{fournisseur}` (public) | Notification serveur à serveur ; 401 si signature invalide |
| Tables `transactions_paiement`, `notifications_paiement` (V37) | Statuts `EN_ATTENTE → REUSSI / ECHEC / EXPIRE` ; rapprochement |

Activation future : implémenter `FournisseurPaiement` pour le fournisseur retenu (signature selon sa
documentation), puis `app.paiement.fournisseur=<NOM>` et les secrets en variables d'environnement.
Tests : `PaiementEtSmsIT` (règles avec fournisseur fictif), `PaiementDesactiveIT` (défaut désactivé).

Rapprochement : comparer chaque jour `transactions_paiement` (statut, montant) avec le relevé du
fournisseur ; toute transaction `EN_ATTENTE` expirée ou tout écart doit être traité manuellement.

## 3. SMS — comparaison indicative (Togo)

Prix relevés le 02/11/2026 sur des pages publiques, **à confirmer par devis** (ils varient selon
l'opérateur de destination et le volume).

| Fournisseur | Prix indicatif / SMS vers le Togo | Remarques |
|---|---|---|
| Plivo | ~0,27 $ (Moov) à ~0,46 $ (Togocel) | Grille publique par opérateur |
| D7 Networks | ~0,29 $ | Tarif unique affiché |
| Twilio | non lisible sur la page publique | Dépend du type d'expéditeur |
| Agrégateurs locaux / opérateurs | ~50–100 FCFA (source tierce, non confirmée) | Contrat local, expéditeur alphanumérique à déclarer |

Recommandation : demander un devis à au moins un agrégateur local et un acteur international, vérifier
l'enregistrement de l'expéditeur et la conformité (consentement des salariés, données personnelles).
WhatsApp Business : passe par un fournisseur agréé Meta et des modèles de messages approuvés.

## 4. Mobile money — comparaison indicative (Togo : T-Money, Flooz/Moov Money)

| Fournisseur | Moyens | Frais indicatifs (sources tierces) | Remarques |
|---|---|---|---|
| CinetPay | T-Money, Flooz, cartes | ~1,8–2,2 % | Agrégateur établi en Afrique de l'Ouest |
| PayDunya | T-Money, Flooz, Wave, cartes | ~1,5–2 % | Webhooks signés (SHA-512) |
| PayGate Global | Flooz, T-Money | 2,5 % (Flooz), 3 % (T-Money) | Acteur togolais |
| FeexPay, Hub2 | T-Money, Moov | à demander | — |
| API opérateur directe (Togocom, Moov) | un opérateur chacun | à négocier | Société immatriculée au Togo exigée |

Prérequis avant toute activation : société et compte marchand, contrat signé, accès sandbox, identifiants
et secrets de signature, test en sandbox des cas réussi / échec / expiré / notification rejouée, URL de
notification en HTTPS publique, procédure de rapprochement et de remboursement.

## Sources

- [Plivo — tarifs SMS Togo](https://www.plivo.com/sms/pricing/tg/)
- [D7 Networks — SMS Togo](https://d7networks.com/sms/togo/)
- [Twilio — tarifs SMS Togo](https://www.twilio.com/en-us/sms/pricing/tg)
- [sent.dm — comparatif SMS Togo](https://www.sent.dm/en/resources/sms-pricing/togo-sms-pricing)
- [TechCabal — PayDunya au Togo](https://techcabal.com/2022/03/02/paydunya-expands-to-togo/)
- [Kolonell — intégrer T-Money et Flooz (2026)](https://kolonell.com/fr/blog/integrer-paiement-mobile-togo-tmoney-flooz-2026)
- [Packagist — laravel-paygate-global](https://packagist.org/packages/filano/laravel-paygate-global)
