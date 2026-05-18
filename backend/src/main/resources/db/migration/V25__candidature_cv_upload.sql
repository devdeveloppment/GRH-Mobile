-- Ajout du stockage local CV et lettre de motivation sur candidatures
ALTER TABLE candidatures
    ADD COLUMN IF NOT EXISTS cv_path        VARCHAR(500),
    ADD COLUMN IF NOT EXISTS cv_nom_fichier VARCHAR(255),
    ADD COLUMN IF NOT EXISTS lettre_motivation TEXT;
