CREATE TABLE employe_qr_codes (
    id          BIGSERIAL    PRIMARY KEY,
    employe_id  BIGINT       NOT NULL UNIQUE REFERENCES employes(id) ON DELETE CASCADE,
    token       VARCHAR(255) NOT NULL UNIQUE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_employe_qr_codes_token ON employe_qr_codes(token);
