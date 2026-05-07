CREATE TABLE notifications (
    id          BIGSERIAL PRIMARY KEY,
    utilisateur_id BIGINT NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    titre       VARCHAR(255) NOT NULL,
    message     TEXT NOT NULL,
    type        VARCHAR(50) NOT NULL DEFAULT 'INFO',
    lu          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP WITH TIME ZONE,
    updated_at  TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_notifications_utilisateur_id ON notifications(utilisateur_id);
CREATE INDEX idx_notifications_utilisateur_lu  ON notifications(utilisateur_id, lu);
