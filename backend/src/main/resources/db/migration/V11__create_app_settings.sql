CREATE TABLE app_settings (
    id      BIGSERIAL PRIMARY KEY,
    key     VARCHAR(100) NOT NULL UNIQUE,
    value   VARCHAR(500) NOT NULL DEFAULT 'false'
);

INSERT INTO app_settings (key, value) VALUES
    ('SSO', 'false'),
    ('NOTIFICATIONS', 'true'),
    ('AUTO_LOGOUT', 'true'),
    ('TWO_FACTOR', 'false');
