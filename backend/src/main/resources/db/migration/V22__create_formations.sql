CREATE TABLE formations (
    id              BIGSERIAL PRIMARY KEY,
    titre           VARCHAR(255) NOT NULL,
    description     TEXT,
    type            VARCHAR(50)  NOT NULL DEFAULT 'INTERNE',
    formateur       VARCHAR(255),
    duree_heures    INTEGER,
    statut          VARCHAR(30)  NOT NULL DEFAULT 'PLANIFIEE',
    date_debut      DATE,
    date_fin        DATE,
    budget          NUMERIC(14,2),
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ
);

CREATE TABLE participations_formation (
    id              BIGSERIAL PRIMARY KEY,
    formation_id    BIGINT      NOT NULL REFERENCES formations(id) ON DELETE CASCADE,
    employe_id      BIGINT      NOT NULL REFERENCES employes(id)   ON DELETE CASCADE,
    statut          VARCHAR(30) NOT NULL DEFAULT 'INSCRIT',
    note            INTEGER,
    certificat_url  VARCHAR(500),
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    UNIQUE(formation_id, employe_id)
);

CREATE INDEX idx_formations_statut        ON formations(statut);
CREATE INDEX idx_participations_formation ON participations_formation(formation_id);
CREATE INDEX idx_participations_employe   ON participations_formation(employe_id);
