-- Champ de redirection : route Flutter à ouvrir au tap (ex: /rh/conges, /employee/home)
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS redirect_to VARCHAR(255);

-- Timestamp de lecture
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS read_at TIMESTAMP WITH TIME ZONE;

-- Index pour le nettoyage automatique (purge des notifs lues > 90 jours)
CREATE INDEX IF NOT EXISTS idx_notifications_read_at ON notifications(read_at)
    WHERE lu = TRUE;
