-- ============================================================================
-- V32 : architecture multi-entreprise (décision D1 : base partagée + entreprise_id + RLS).
--
-- * Toutes les données existantes sont rattachées à l'entreprise n° 1 (aucune perte).
-- * Unicités métier rendues propres à chaque entreprise (matricule, codes, dates…).
--   L'e-mail de connexion reste unique globalement (décision D2).
-- * Permissions communes à toutes les entreprises (décision D3) : tables globales.
-- * RLS PostgreSQL activée ET forcée (s'applique aussi au propriétaire des tables) :
--   une ligne n'est visible / modifiable que si app.entreprise_id vaut son entreprise_id
--   (ou -1 : contexte système). Variable absente = aucune ligne (fail closed).
--
-- IMPORTANT pour les migrations suivantes : commencer par
--   SELECT set_config('app.entreprise_id', '-1', false);
-- sinon les UPDATE/DELETE de données ne verront aucune ligne.
-- ============================================================================

CREATE TABLE entreprises (
    id              BIGSERIAL PRIMARY KEY,
    nom             VARCHAR(200) NOT NULL,
    slug            VARCHAR(60)  NOT NULL UNIQUE,
    statut          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    offre           VARCHAR(30)  NOT NULL DEFAULT 'ESSAI',
    date_fin_essai  DATE,
    pays            VARCHAR(2)   NOT NULL DEFAULT 'TG',
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ,
    CONSTRAINT entreprises_slug_format CHECK (slug ~ '^[a-z0-9][a-z0-9-]{1,58}[a-z0-9]$'),
    CONSTRAINT entreprises_statut CHECK (statut IN ('ACTIVE', 'SUSPENDUE')),
    CONSTRAINT entreprises_offre CHECK (offre IN ('ESSAI', 'ESSENTIEL', 'PRO', 'SUR_MESURE'))
);

INSERT INTO entreprises (id, nom, slug, statut, offre)
VALUES (1, 'Entreprise principale', 'defaut', 'ACTIVE', 'SUR_MESURE');
SELECT setval('entreprises_id_seq', 1, true);

-- parametres_rh : clé primaire technique (la clé métier devient unique par entreprise).
ALTER TABLE parametres_rh DROP CONSTRAINT parametres_rh_pkey;
ALTER TABLE parametres_rh ADD COLUMN id BIGSERIAL PRIMARY KEY;

-- Colonne entreprise_id sur toutes les tables métier.
DO $$
DECLARE
    t TEXT;
    tables TEXT[] := ARRAY[
        'acquisitions_conges', 'app_settings', 'audit_logs', 'candidatures', 'competences', 'conges',
        'contrats', 'departements', 'documents', 'employes', 'employe_qr_codes', 'entretiens',
        'evaluations', 'fiches_paie', 'formations', 'jours_feries', 'lignes_bulletin', 'notes_frais',
        'notifications', 'objectifs', 'offres_emploi', 'parametres_paie', 'parametres_rh',
        'participations_formation', 'postes', 'presences', 'rubriques_paie', 'services',
        'taches_integration', 'utilisateurs'];
BEGIN
    FOREACH t IN ARRAY tables LOOP
        EXECUTE format('ALTER TABLE %I ADD COLUMN entreprise_id BIGINT NOT NULL DEFAULT 1 REFERENCES entreprises(id)', t);
        -- Plus de valeur par défaut : toute insertion doit désigner son entreprise explicitement.
        EXECUTE format('ALTER TABLE %I ALTER COLUMN entreprise_id DROP DEFAULT', t);
        EXECUTE format('CREATE INDEX %I ON %I (entreprise_id)', 'idx_' || t || '_entreprise', t);
    END LOOP;
END $$;

-- Unicités : de globales à « par entreprise ».
DO $$
DECLARE
    r RECORD;
    cible RECORD;
BEGIN
    FOR cible IN SELECT * FROM (VALUES
        ('employes', 'matricule'), ('departements', 'code'), ('postes', 'code'),
        ('rubriques_paie', 'code'), ('jours_feries', 'date'), ('app_settings', 'key'),
        ('services', 'nom')) AS v(tbl, col)
    LOOP
        FOR r IN
            SELECT c.conname
            FROM pg_constraint c
            JOIN pg_class rel ON rel.oid = c.conrelid
            JOIN pg_attribute a ON a.attrelid = rel.oid AND a.attnum = ANY (c.conkey)
            WHERE rel.relname = cible.tbl AND c.contype = 'u' AND a.attname = cible.col
              AND array_length(c.conkey, 1) = 1
        LOOP
            EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', cible.tbl, r.conname);
        END LOOP;
        EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I UNIQUE (entreprise_id, %I)',
            cible.tbl, 'uq_' || cible.tbl || '_entreprise_' || cible.col, cible.col);
    END LOOP;
END $$;

ALTER TABLE parametres_paie DROP CONSTRAINT parametres_paie_unique;
ALTER TABLE parametres_paie ADD CONSTRAINT parametres_paie_unique UNIQUE (entreprise_id, code, date_debut);
ALTER TABLE parametres_rh ADD CONSTRAINT uq_parametres_rh_entreprise_cle UNIQUE (entreprise_id, cle);

-- Entreprise courante pour la session SQL (NULL si non définie).
CREATE FUNCTION app_entreprise_courante() RETURNS BIGINT
LANGUAGE sql STABLE AS $$
    SELECT NULLIF(current_setting('app.entreprise_id', true), '')::BIGINT
$$;

-- RLS : défense en profondeur, indépendante de l'application.
DO $$
DECLARE
    t TEXT;
    tables TEXT[] := ARRAY[
        'acquisitions_conges', 'app_settings', 'audit_logs', 'candidatures', 'competences', 'conges',
        'contrats', 'departements', 'documents', 'employes', 'employe_qr_codes', 'entretiens',
        'evaluations', 'fiches_paie', 'formations', 'jours_feries', 'lignes_bulletin', 'notes_frais',
        'notifications', 'objectifs', 'offres_emploi', 'parametres_paie', 'parametres_rh',
        'participations_formation', 'postes', 'presences', 'rubriques_paie', 'services',
        'taches_integration', 'utilisateurs'];
BEGIN
    FOREACH t IN ARRAY tables LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
        EXECUTE format(
            'CREATE POLICY isolation_entreprise ON %I '
            || 'USING (entreprise_id = app_entreprise_courante() OR app_entreprise_courante() = -1) '
            || 'WITH CHECK (entreprise_id = app_entreprise_courante() OR app_entreprise_courante() = -1)', t);
    END LOOP;
END $$;
