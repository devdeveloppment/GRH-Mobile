CREATE TABLE departements (
    id              BIGSERIAL PRIMARY KEY,
    code            VARCHAR(50)  NOT NULL UNIQUE,
    nom             VARCHAR(255) NOT NULL,
    description     TEXT,
    parent_id       BIGINT REFERENCES departements(id) ON DELETE SET NULL,
    manager_id      BIGINT REFERENCES employes(id) ON DELETE SET NULL,
    actif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ
);

CREATE TABLE postes (
    id              BIGSERIAL PRIMARY KEY,
    code            VARCHAR(50)  NOT NULL UNIQUE,
    intitule        VARCHAR(255) NOT NULL,
    departement_id  BIGINT REFERENCES departements(id) ON DELETE SET NULL,
    niveau          VARCHAR(50),
    salaire_min     NUMERIC(14,2),
    salaire_max     NUMERIC(14,2),
    description     TEXT,
    actif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ
);

CREATE INDEX idx_departements_parent  ON departements(parent_id);
CREATE INDEX idx_departements_manager ON departements(manager_id);
CREATE INDEX idx_postes_departement   ON postes(departement_id);
