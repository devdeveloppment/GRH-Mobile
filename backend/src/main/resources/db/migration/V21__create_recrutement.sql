CREATE TABLE offres_emploi (
    id              BIGSERIAL PRIMARY KEY,
    poste_id        BIGINT REFERENCES postes(id) ON DELETE SET NULL,
    departement_id  BIGINT REFERENCES departements(id) ON DELETE SET NULL,
    titre           VARCHAR(255) NOT NULL,
    description     TEXT,
    statut          VARCHAR(30)  NOT NULL DEFAULT 'PUBLIEE',
    date_limite     DATE,
    created_by      BIGINT REFERENCES utilisateurs(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ
);

CREATE TABLE candidatures (
    id          BIGSERIAL PRIMARY KEY,
    offre_id    BIGINT       NOT NULL REFERENCES offres_emploi(id) ON DELETE CASCADE,
    nom         VARCHAR(255) NOT NULL,
    prenom      VARCHAR(255) NOT NULL,
    email       VARCHAR(255) NOT NULL,
    telephone   VARCHAR(50),
    cv_url      VARCHAR(500),
    statut      VARCHAR(30)  NOT NULL DEFAULT 'RECUE',
    note        INTEGER,
    commentaire TEXT,
    created_at  TIMESTAMPTZ,
    updated_at  TIMESTAMPTZ
);

CREATE TABLE entretiens (
    id              BIGSERIAL PRIMARY KEY,
    candidature_id  BIGINT      NOT NULL REFERENCES candidatures(id) ON DELETE CASCADE,
    intervieweur_id BIGINT REFERENCES utilisateurs(id) ON DELETE SET NULL,
    date_heure      TIMESTAMPTZ NOT NULL,
    type            VARCHAR(30) NOT NULL DEFAULT 'TELEPHONE',
    note            INTEGER,
    compte_rendu    TEXT,
    statut          VARCHAR(20) NOT NULL DEFAULT 'PLANIFIE',
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ
);

CREATE INDEX idx_offres_statut      ON offres_emploi(statut);
CREATE INDEX idx_candidatures_offre ON candidatures(offre_id);
CREATE INDEX idx_entretiens_cand    ON entretiens(candidature_id);
