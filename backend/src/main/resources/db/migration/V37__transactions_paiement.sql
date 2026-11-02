-- V37 : transactions de paiement (abonnements SaaS des entreprises clientes), intégration désactivée.
-- Table de la plateforme (gérée par le SUPER_ADMIN) : pas de RLS, accès réservé côté API.
CREATE TABLE transactions_paiement (
    id                     BIGSERIAL PRIMARY KEY,
    reference              VARCHAR(64)  NOT NULL UNIQUE,
    entreprise_id          BIGINT       NOT NULL REFERENCES entreprises(id),
    fournisseur            VARCHAR(40)  NOT NULL,
    reference_fournisseur  VARCHAR(120),
    montant                NUMERIC(14, 2) NOT NULL CHECK (montant > 0),
    devise                 VARCHAR(3)   NOT NULL DEFAULT 'XOF',
    statut                 VARCHAR(20)  NOT NULL DEFAULT 'EN_ATTENTE',
    description            VARCHAR(200),
    cle_idempotence        VARCHAR(100) NOT NULL UNIQUE,
    expire_le              TIMESTAMPTZ  NOT NULL,
    confirme_le            TIMESTAMPTZ,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ,
    CONSTRAINT transactions_paiement_statut CHECK (statut IN ('EN_ATTENTE', 'REUSSI', 'ECHEC', 'EXPIRE'))
);

-- Journal brut des notifications reçues (signature valide ou non), pour le rapprochement.
CREATE TABLE notifications_paiement (
    id               BIGSERIAL PRIMARY KEY,
    fournisseur      VARCHAR(40)  NOT NULL,
    signature_valide BOOLEAN      NOT NULL,
    reference        VARCHAR(64),
    corps            TEXT         NOT NULL,
    recu_le          TIMESTAMPTZ  NOT NULL DEFAULT now()
);
