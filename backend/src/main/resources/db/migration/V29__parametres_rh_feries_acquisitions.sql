-- Paramètres RH de l'entreprise, jours fériés et acquisitions de congés.
-- Aucune valeur réglementaire n'est imposée : les valeurs par défaut conservent le comportement existant.

CREATE TABLE parametres_rh (
    cle          VARCHAR(80) PRIMARY KEY,
    valeur       VARCHAR(200),
    description  TEXT,
    updated_at   TIMESTAMPTZ
);

INSERT INTO parametres_rh (cle, valeur, description) VALUES
 ('CONGES_MODE_DECOMPTE', 'CALENDAIRES',
  'Décompte des jours de congé : CALENDAIRES (tous les jours), OUVRABLES (lundi-samedi hors fériés) ou OUVRES (lundi-vendredi hors fériés). À valider selon le Code du travail applicable.'),
 ('CONGES_ACQUISITION_JOURS_PAR_MOIS', NULL,
  'Jours de congé acquis par mois de travail. Vide = acquisition automatique désactivée. Valeur légale à faire valider.'),
 ('HEURES_JOUR_NORMALES', NULL,
  'Durée normale de travail par jour, en heures. Vide = calcul des heures supplémentaires désactivé. Valeur légale à faire valider.');

CREATE TABLE jours_feries (
    id          BIGSERIAL PRIMARY KEY,
    date        DATE NOT NULL UNIQUE,
    libelle     VARCHAR(200) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ
);

CREATE TABLE acquisitions_conges (
    id          BIGSERIAL PRIMARY KEY,
    employe_id  BIGINT NOT NULL REFERENCES employes(id) ON DELETE CASCADE,
    periode     VARCHAR(7) NOT NULL,
    jours       NUMERIC(6, 2) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ,
    CONSTRAINT acquisitions_conges_unique UNIQUE (employe_id, periode)
);
