-- V35 : arrivées et départs — responsable et commentaire par tâche, clôture du processus.

ALTER TABLE taches_integration
    ADD COLUMN responsable  VARCHAR(200),
    ADD COLUMN commentaire  TEXT;

CREATE TABLE clotures_integration (
    id             BIGSERIAL PRIMARY KEY,
    entreprise_id  BIGINT NOT NULL REFERENCES entreprises(id),
    employe_id     BIGINT NOT NULL REFERENCES employes(id) ON DELETE CASCADE,
    type           VARCHAR(10) NOT NULL,
    cloture_par    BIGINT REFERENCES utilisateurs(id),
    cloture_le     TIMESTAMPTZ NOT NULL DEFAULT now(),
    commentaire    TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ,
    CONSTRAINT clotures_integration_type CHECK (type IN ('ARRIVEE', 'DEPART')),
    CONSTRAINT uq_clotures_integration UNIQUE (entreprise_id, employe_id, type)
);

ALTER TABLE clotures_integration ENABLE ROW LEVEL SECURITY;
ALTER TABLE clotures_integration FORCE ROW LEVEL SECURITY;
CREATE POLICY isolation_entreprise ON clotures_integration
    USING (entreprise_id = app_entreprise_courante() OR app_entreprise_courante() = -1)
    WITH CHECK (entreprise_id = app_entreprise_courante() OR app_entreprise_courante() = -1);
