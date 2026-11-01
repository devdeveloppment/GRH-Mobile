-- Moteur de paie paramétrable.
-- AUCUN taux réglementaire n'est inséré ici : les paramètres légaux (CNSS, IRPP, etc.)
-- doivent être saisis depuis des sources officielles et validés par un expert-comptable.

CREATE TABLE parametres_paie (
    id               BIGSERIAL PRIMARY KEY,
    code             VARCHAR(60)  NOT NULL,
    libelle          VARCHAR(200) NOT NULL,
    valeur           NUMERIC(18, 6) NOT NULL,
    date_debut       DATE NOT NULL,
    date_fin         DATE,
    source           TEXT,
    valide_par       VARCHAR(200),
    date_validation  DATE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ,
    CONSTRAINT parametres_paie_code_format CHECK (code ~ '^[A-Z][A-Z0-9_]*$'),
    CONSTRAINT parametres_paie_periode CHECK (date_fin IS NULL OR date_fin >= date_debut),
    CONSTRAINT parametres_paie_unique UNIQUE (code, date_debut)
);

CREATE TABLE rubriques_paie (
    id          BIGSERIAL PRIMARY KEY,
    code        VARCHAR(60)  NOT NULL UNIQUE,
    libelle     VARCHAR(200) NOT NULL,
    type        VARCHAR(30)  NOT NULL,
    ordre       INTEGER      NOT NULL,
    formule     TEXT         NOT NULL,
    actif       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ,
    CONSTRAINT rubriques_paie_code_format CHECK (code ~ '^[A-Z][A-Z0-9_]*$'),
    CONSTRAINT rubriques_paie_type CHECK (type IN ('GAIN', 'COTISATION_SALARIALE', 'IMPOT', 'RETENUE'))
);

CREATE TABLE lignes_bulletin (
    id                    BIGSERIAL PRIMARY KEY,
    fiche_paie_id         BIGINT NOT NULL REFERENCES fiches_paie(id) ON DELETE CASCADE,
    rubrique_code         VARCHAR(60)  NOT NULL,
    libelle               VARCHAR(200) NOT NULL,
    type                  VARCHAR(30)  NOT NULL,
    ordre                 INTEGER      NOT NULL,
    montant               NUMERIC(18, 2) NOT NULL,
    formule               TEXT NOT NULL,
    parametres_utilises   TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ
);
CREATE INDEX idx_lignes_bulletin_fiche ON lignes_bulletin(fiche_paie_id);

ALTER TABLE fiches_paie
    ADD COLUMN autres_retenues          NUMERIC(18, 2) NOT NULL DEFAULT 0,
    ADD COLUMN conforme_reglementation  BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN avertissement            TEXT;

-- Les fiches calculées avant ce moteur utilisaient des taux fixes non validés.
UPDATE fiches_paie
SET avertissement = 'Calcul antérieur au moteur paramétrable : taux non validés, ne constitue pas un bulletin légal.'
WHERE avertissement IS NULL;

-- Seule rubrique fournie par défaut : le salaire de base (aucune règle légale).
INSERT INTO rubriques_paie (code, libelle, type, ordre, formule)
VALUES ('SALAIRE_BASE', 'Salaire de base', 'GAIN', 10, 'SALAIRE_BASE');
