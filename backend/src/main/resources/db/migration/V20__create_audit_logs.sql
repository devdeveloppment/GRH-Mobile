CREATE TABLE audit_logs (
    id          BIGSERIAL PRIMARY KEY,
    acteur_id   BIGINT REFERENCES utilisateurs(id) ON DELETE SET NULL,
    action      VARCHAR(100) NOT NULL,
    entite      VARCHAR(100) NOT NULL,
    entite_id   BIGINT,
    avant       JSONB,
    apres       JSONB,
    ip_address  VARCHAR(45),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_entite  ON audit_logs(entite, entite_id);
CREATE INDEX idx_audit_acteur  ON audit_logs(acteur_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);
