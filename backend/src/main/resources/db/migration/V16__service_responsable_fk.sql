ALTER TABLE services ALTER COLUMN responsable DROP NOT NULL;
ALTER TABLE services ADD COLUMN responsable_id BIGINT REFERENCES employes(id);
CREATE INDEX idx_services_responsable_id ON services(responsable_id);
