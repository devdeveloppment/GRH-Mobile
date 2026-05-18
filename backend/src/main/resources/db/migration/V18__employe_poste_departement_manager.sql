ALTER TABLE employes
    ADD COLUMN IF NOT EXISTS poste_id       BIGINT REFERENCES postes(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS departement_id BIGINT REFERENCES departements(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS manager_id     BIGINT REFERENCES employes(id) ON DELETE SET NULL;

CREATE INDEX idx_employes_poste       ON employes(poste_id);
CREATE INDEX idx_employes_departement ON employes(departement_id);
CREATE INDEX idx_employes_manager     ON employes(manager_id);
