CREATE TABLE permissions (
    id          BIGSERIAL PRIMARY KEY,
    code        VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL
);

CREATE TABLE permission_roles (
    permission_id BIGINT      NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    role          VARCHAR(50) NOT NULL
);

-- Permissions initiales
INSERT INTO permissions (code, description) VALUES
  ('MANAGE_EMPLOYEES', 'Gestion des employés (création, modification, archivage)'),
  ('VIEW_REPORTS',     'Accès aux rapports et tableaux de bord'),
  ('MANAGE_LEAVES',    'Gestion des demandes de congés'),
  ('MANAGE_PAIE',      'Gestion de la paie et validation mensuelle'),
  ('MANAGE_USERS',     'Gestion des comptes utilisateurs et rôles');

-- ADMIN obtient toutes les permissions
INSERT INTO permission_roles (permission_id, role)
SELECT id, 'ADMIN' FROM permissions;

-- RH_MANAGER : employés, congés, présences, paie, rapports
INSERT INTO permission_roles (permission_id, role)
SELECT id, 'RH_MANAGER' FROM permissions
WHERE code IN ('MANAGE_EMPLOYEES', 'VIEW_REPORTS', 'MANAGE_LEAVES', 'MANAGE_PAIE');

-- DIRECTION : rapports uniquement
INSERT INTO permission_roles (permission_id, role)
SELECT id, 'DIRECTION' FROM permissions
WHERE code IN ('VIEW_REPORTS');
