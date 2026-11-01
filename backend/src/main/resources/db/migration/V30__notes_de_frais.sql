-- Notes de frais : déclaration par l'employé, validation, remboursement déclaré manuellement.
-- "REMBOURSEE" est une déclaration manuelle du service RH/paie : aucun paiement n'est effectué par l'application.

CREATE TABLE notes_frais (
    id                    BIGSERIAL PRIMARY KEY,
    employe_id            BIGINT NOT NULL REFERENCES employes(id),
    date_depense          DATE NOT NULL,
    categorie             VARCHAR(30) NOT NULL,
    montant               NUMERIC(14, 2) NOT NULL,
    devise                VARCHAR(3) NOT NULL DEFAULT 'XOF',
    description           TEXT NOT NULL,
    justificatif_path     VARCHAR(255),
    justificatif_nom      VARCHAR(255),
    statut                VARCHAR(20) NOT NULL DEFAULT 'SOUMISE',
    decideur_id           BIGINT REFERENCES utilisateurs(id),
    date_decision         TIMESTAMPTZ,
    commentaire           TEXT,
    reference_remboursement VARCHAR(100),
    date_remboursement    TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ,
    CONSTRAINT notes_frais_montant CHECK (montant > 0),
    CONSTRAINT notes_frais_statut CHECK (statut IN ('SOUMISE', 'APPROUVEE', 'REFUSEE', 'REMBOURSEE')),
    CONSTRAINT notes_frais_categorie CHECK (categorie IN ('TRANSPORT', 'REPAS', 'HEBERGEMENT', 'FOURNITURES', 'COMMUNICATION', 'AUTRE'))
);

CREATE INDEX idx_notes_frais_employe ON notes_frais(employe_id);
CREATE INDEX idx_notes_frais_statut ON notes_frais(statut);
