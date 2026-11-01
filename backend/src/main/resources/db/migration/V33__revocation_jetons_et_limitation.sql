-- V33 : révocation des jetons JWT et limitation du nombre de requêtes.
-- Tables techniques globales (sans entreprise_id ni RLS) : elles ne contiennent aucune donnée RH.

-- Version de session par utilisateur : incrémentée lors d'un changement de mot de passe, d'une
-- désactivation, d'un changement de rôle ou d'une révocation administrative. Un jeton portant une
-- version antérieure est refusé.
ALTER TABLE utilisateurs ADD COLUMN token_version INTEGER NOT NULL DEFAULT 0;

-- Jetons révoqués individuellement (déconnexion). Purgés une fois expirés.
CREATE TABLE jetons_revoques (
    jti        VARCHAR(64) PRIMARY KEY,
    expire_le  TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_jetons_revoques_expire ON jetons_revoques (expire_le);

-- Compteurs de limitation partagés par toutes les instances de l'API (fenêtre fixe).
CREATE TABLE limites_requetes (
    cle           VARCHAR(200) NOT NULL,
    fenetre_debut TIMESTAMPTZ  NOT NULL,
    compteur      INTEGER      NOT NULL DEFAULT 0,
    PRIMARY KEY (cle, fenetre_debut)
);
CREATE INDEX idx_limites_requetes_fenetre ON limites_requetes (fenetre_debut);
