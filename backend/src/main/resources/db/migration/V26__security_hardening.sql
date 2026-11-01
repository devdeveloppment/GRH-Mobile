-- Changement de mot de passe obligatoire après attribution d'un mot de passe temporaire
ALTER TABLE utilisateurs
    ADD COLUMN IF NOT EXISTS doit_changer_mot_de_passe BOOLEAN NOT NULL DEFAULT FALSE;

-- Séquence de génération des matricules (évite les collisions basées sur count())
CREATE SEQUENCE IF NOT EXISTS employe_matricule_seq START WITH 1000;
