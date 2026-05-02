-- Unicité : un seul bulletin de paie par employé et par période
ALTER TABLE fiches_paie
    ADD CONSTRAINT uq_fiches_paie_employe_periode UNIQUE (employe_id, periode);

-- Indexes de performance pour les jointures fréquentes
CREATE INDEX IF NOT EXISTS idx_conges_employe_id     ON conges(employe_id);
CREATE INDEX IF NOT EXISTS idx_fiches_paie_employe_id ON fiches_paie(employe_id);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_email     ON utilisateurs(lower(email));
CREATE INDEX IF NOT EXISTS idx_presences_employe_id   ON presences(employe_id);
