CREATE TABLE objectifs (
    id              BIGSERIAL PRIMARY KEY,
    employe_id      BIGINT NOT NULL REFERENCES employes(id) ON DELETE CASCADE,
    titre           VARCHAR(255) NOT NULL,
    description     TEXT,
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_COURS',
    date_echeance   DATE,
    created_at      TIMESTAMP WITH TIME ZONE,
    updated_at      TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_objectifs_employe ON objectifs(employe_id);

CREATE TABLE evaluations (
    id              BIGSERIAL PRIMARY KEY,
    employe_id      BIGINT NOT NULL REFERENCES employes(id) ON DELETE CASCADE,
    evaluateur_id   BIGINT REFERENCES utilisateurs(id),
    periode         VARCHAR(20) NOT NULL,
    note            INTEGER NOT NULL CHECK (note BETWEEN 0 AND 10),
    commentaire     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE,
    updated_at      TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_evaluations_employe ON evaluations(employe_id);
