CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    employe_id BIGINT NOT NULL REFERENCES employes(id),
    nom VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    taille_ko INTEGER NOT NULL DEFAULT 0,
    url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE competences (
    id BIGSERIAL PRIMARY KEY,
    employe_id BIGINT NOT NULL REFERENCES employes(id),
    libelle VARCHAR(255) NOT NULL,
    niveau INTEGER NOT NULL DEFAULT 50,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_documents_employe ON documents(employe_id);
CREATE INDEX idx_competences_employe ON competences(employe_id);
