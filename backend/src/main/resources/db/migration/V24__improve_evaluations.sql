ALTER TABLE evaluations
    ADD COLUMN IF NOT EXISTS type              VARCHAR(30)   NOT NULL DEFAULT 'ANNUELLE',
    ADD COLUMN IF NOT EXISTS statut            VARCHAR(20)   NOT NULL DEFAULT 'BROUILLON',
    ADD COLUMN IF NOT EXISTS note_competences  NUMERIC(4,2),
    ADD COLUMN IF NOT EXISTS note_objectifs    NUMERIC(4,2),
    ADD COLUMN IF NOT EXISTS note_comportement NUMERIC(4,2);

CREATE INDEX IF NOT EXISTS idx_evaluations_employe ON evaluations(employe_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_statut  ON evaluations(statut);
