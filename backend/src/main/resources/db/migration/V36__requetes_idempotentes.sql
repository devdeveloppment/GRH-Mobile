-- V36 : rejeu sans doublon des opérations envoyées depuis le mode hors ligne (en-tête Idempotency-Key).
-- Table technique : la clé est propre à un utilisateur ; la réponse d'origine est renvoyée en cas de rejeu.
CREATE TABLE requetes_idempotentes (
    utilisateur_id  BIGINT       NOT NULL,
    cle             VARCHAR(100) NOT NULL,
    requete         VARCHAR(300) NOT NULL,
    statut          INTEGER,
    corps           TEXT,
    cree_le         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (utilisateur_id, cle)
);
CREATE INDEX idx_requetes_idempotentes_date ON requetes_idempotentes (cree_le);
