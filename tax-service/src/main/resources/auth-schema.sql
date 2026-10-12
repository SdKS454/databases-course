CREATE TABLE IF NOT EXISTS app_user (
    id BIGSERIAL PRIMARY KEY,
    login VARCHAR(40) NOT NULL UNIQUE,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    patronymic VARCHAR(60) NOT NULL,
    password_hash CHAR(64) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE tax_payment
    ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES app_user(id);

CREATE INDEX IF NOT EXISTS idx_tax_payment_user_id
    ON tax_payment(user_id);
