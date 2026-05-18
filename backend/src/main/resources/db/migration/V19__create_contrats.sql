CREATE TABLE contrats (
    id              BIGSERIAL PRIMARY KEY,
    employe_id      BIGINT NOT NULL REFERENCES employes(id) ON DELETE CASCADE,
    type_contrat    VARCHAR(50)   NOT NULL,
    date_debut      DATE          NOT NULL,
    date_fin        DATE,
    salaire_brut    NUMERIC(14,2) NOT NULL,
    poste_id        BIGINT REFERENCES postes(id) ON DELETE SET NULL,
    departement_id  BIGINT REFERENCES departements(id) ON DELETE SET NULL,
    statut          VARCHAR(20)   NOT NULL DEFAULT 'ACTIF',
    document_url    VARCHAR(500),
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ
);

CREATE INDEX idx_contrats_employe ON contrats(employe_id);
CREATE INDEX idx_contrats_statut  ON contrats(statut);
