-- Les permissions deviennent effectives : on aligne les rôles RH et paie sur les droits existants.
INSERT INTO permission_roles (permission_id, role)
SELECT p.id, 'HR_ADMIN' FROM permissions p
WHERE p.code IN ('MANAGE_EMPLOYEES', 'VIEW_REPORTS', 'MANAGE_LEAVES', 'MANAGE_PAIE')
  AND NOT EXISTS (SELECT 1 FROM permission_roles pr WHERE pr.permission_id = p.id AND pr.role = 'HR_ADMIN');

INSERT INTO permission_roles (permission_id, role)
SELECT p.id, 'PAYROLL_OFFICER' FROM permissions p
WHERE p.code IN ('MANAGE_PAIE', 'VIEW_REPORTS')
  AND NOT EXISTS (SELECT 1 FROM permission_roles pr WHERE pr.permission_id = p.id AND pr.role = 'PAYROLL_OFFICER');

-- Options non implémentées retirées des paramètres
DELETE FROM app_settings WHERE key IN ('SSO', 'TWO_FACTOR');
