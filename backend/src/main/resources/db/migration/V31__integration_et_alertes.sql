-- Listes de tâches d'arrivée (onboarding) et de départ (offboarding), et anti-doublon des alertes automatiques.

CREATE TABLE taches_integration (
    id           BIGSERIAL PRIMARY KEY,
    employe_id   BIGINT NOT NULL REFERENCES employes(id) ON DELETE CASCADE,
    type         VARCHAR(10) NOT NULL,
    libelle      VARCHAR(255) NOT NULL,
    ordre        INTEGER NOT NULL DEFAULT 0,
    echeance     DATE,
    faite        BOOLEAN NOT NULL DEFAULT FALSE,
    faite_par    BIGINT REFERENCES utilisateurs(id),
    faite_le     TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ,
    CONSTRAINT taches_integration_type CHECK (type IN ('ARRIVEE', 'DEPART'))
);
CREATE INDEX idx_taches_integration_employe ON taches_integration(employe_id);

CREATE TABLE alertes_automatiques (
    cle         VARCHAR(200) PRIMARY KEY,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
