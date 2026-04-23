CREATE TABLE services (
    id BIGSERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL,
    responsable VARCHAR(255) NOT NULL,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE utilisateurs (
    id BIGSERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    mot_de_passe VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    date_creation TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE employes (
    id BIGSERIAL PRIMARY KEY,
    matricule VARCHAR(255) NOT NULL UNIQUE,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    date_naissance DATE,
    genre VARCHAR(50),
    nationalite VARCHAR(255),
    email VARCHAR(255) NOT NULL,
    telephone VARCHAR(255),
    statut VARCHAR(255) NOT NULL,
    date_embauche DATE,
    poste VARCHAR(255) NOT NULL,
    service_id BIGINT REFERENCES services(id),
    type_contrat VARCHAR(50) NOT NULL,
    adresse TEXT,
    date_fin_contrat DATE,
    photo_url VARCHAR(500),
    solde_conge NUMERIC(10, 2) NOT NULL DEFAULT 30,
    salaire_brut_base NUMERIC(14, 2) NOT NULL DEFAULT 0,
    utilisateur_id BIGINT UNIQUE REFERENCES utilisateurs(id),
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE conges (
    id BIGSERIAL PRIMARY KEY,
    employe_id BIGINT NOT NULL REFERENCES employes(id),
    type_conge VARCHAR(50) NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    nombre_jours INTEGER NOT NULL,
    statut VARCHAR(50) NOT NULL,
    motif TEXT,
    commentaire TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE presences (
    id BIGSERIAL PRIMARY KEY,
    employe_id BIGINT NOT NULL REFERENCES employes(id),
    date DATE NOT NULL,
    heure_arrivee TIMESTAMP,
    heure_depart TIMESTAMP,
    statut VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE fiches_paie (
    id BIGSERIAL PRIMARY KEY,
    employe_id BIGINT NOT NULL REFERENCES employes(id),
    periode VARCHAR(20) NOT NULL,
    salaire_brut NUMERIC(14, 2) NOT NULL DEFAULT 0,
    cotisations NUMERIC(14, 2) NOT NULL DEFAULT 0,
    impots NUMERIC(14, 2) NOT NULL DEFAULT 0,
    indemnites NUMERIC(14, 2) NOT NULL DEFAULT 0,
    salaire_net NUMERIC(14, 2) NOT NULL DEFAULT 0,
    calculee BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_employes_statut ON employes(statut);
CREATE INDEX idx_presences_date ON presences(date);
CREATE INDEX idx_conges_statut ON conges(statut);
CREATE INDEX idx_fiches_paie_periode ON fiches_paie(periode);
