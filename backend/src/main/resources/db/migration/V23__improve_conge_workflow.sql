ALTER TABLE conges
    ADD COLUMN IF NOT EXISTS approbateur_id   BIGINT REFERENCES utilisateurs(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS date_approbation TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS validateur_id    BIGINT REFERENCES utilisateurs(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS date_validation  TIMESTAMPTZ;

-- Nouvelle valeur de statut pour la double validation
-- EN_ATTENTE → APPROUVE_MANAGER → VALIDE (ou REFUSE à n'importe quelle étape)
