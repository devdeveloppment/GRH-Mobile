-- V34 : circuit de validation des paramètres de paie (BROUILLON -> SOUMIS -> VALIDE).
-- Un paramètre n'est appliqué comme règle « validée » que s'il est au statut VALIDE, avec une source
-- officielle et un validateur déclaré (expert-comptable ou juriste). L'application ne vérifie pas la
-- qualification réelle de ce validateur : elle trace la déclaration.
SELECT set_config('app.entreprise_id', '-1', false);

ALTER TABLE parametres_paie
    ADD COLUMN statut              VARCHAR(20)  NOT NULL DEFAULT 'BROUILLON',
    ADD COLUMN soumis_par          BIGINT,
    ADD COLUMN date_soumission     TIMESTAMPTZ,
    ADD COLUMN qualite_validateur  VARCHAR(30),
    ADD COLUMN enregistre_par      BIGINT,
    ADD CONSTRAINT parametres_paie_statut CHECK (statut IN ('BROUILLON', 'SOUMIS', 'VALIDE')),
    ADD CONSTRAINT parametres_paie_qualite CHECK (qualite_validateur IS NULL
        OR qualite_validateur IN ('EXPERT_COMPTABLE', 'JURISTE', 'AUTRE'));

-- Paramètres déjà renseignés avec source et validateur : conservés comme validés (qualité inconnue).
UPDATE parametres_paie SET statut = 'VALIDE', qualite_validateur = 'AUTRE'
 WHERE valide_par IS NOT NULL AND valide_par <> '' AND source IS NOT NULL AND source <> '';
