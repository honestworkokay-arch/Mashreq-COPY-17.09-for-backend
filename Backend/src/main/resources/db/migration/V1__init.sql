CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(320) NOT NULL,
    mobile_number VARCHAR(32) NOT NULL,
    iban VARCHAR(34) NOT NULL,
    account_number VARCHAR(64) NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT customers_email_not_blank CHECK (btrim(email) <> ''),
    CONSTRAINT customers_mobile_not_blank CHECK (btrim(mobile_number) <> ''),
    CONSTRAINT customers_iban_not_blank CHECK (btrim(iban) <> ''),
    CONSTRAINT customers_account_not_blank CHECK (btrim(account_number) <> '')
);

CREATE UNIQUE INDEX customers_email_lower_unique ON customers (lower(email));
CREATE UNIQUE INDEX customers_iban_upper_unique ON customers (upper(replace(iban, ' ', '')));
CREATE UNIQUE INDEX customers_account_number_unique ON customers (account_number);

CREATE TABLE auth_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    token_hash BYTEA NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX auth_sessions_customer_id_idx ON auth_sessions(customer_id);
CREATE INDEX auth_sessions_expires_at_idx ON auth_sessions(expires_at);

CREATE TABLE otp_challenges (
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    purpose VARCHAR(40) NOT NULL,
    channels VARCHAR(64) NOT NULL,
    code_digest BYTEA NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    max_attempts INTEGER NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT otp_attempts_non_negative CHECK (attempts >= 0),
    CONSTRAINT otp_max_attempts_positive CHECK (max_attempts > 0)
);

CREATE INDEX otp_challenges_customer_purpose_idx
    ON otp_challenges(customer_id, purpose, created_at DESC);

CREATE TABLE beneficiaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    nickname VARCHAR(100) NOT NULL,
    full_name VARCHAR(200) NOT NULL,
    bank_name VARCHAR(200) NOT NULL,
    country VARCHAR(100) NOT NULL,
    swift_code VARCHAR(20),
    iban VARCHAR(34) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX beneficiaries_customer_iban_unique
    ON beneficiaries(customer_id, upper(replace(iban, ' ', '')));
CREATE INDEX beneficiaries_customer_created_idx
    ON beneficiaries(customer_id, created_at DESC);

CREATE TABLE banking_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    client_request_id UUID NOT NULL,
    reference VARCHAR(64) NOT NULL UNIQUE,
    transaction_type VARCHAR(40) NOT NULL,
    beneficiary_name VARCHAR(200) NOT NULL,
    beneficiary_bank VARCHAR(200),
    beneficiary_country VARCHAR(100),
    beneficiary_swift VARCHAR(20),
    beneficiary_iban VARCHAR(34),
    sender_account VARCHAR(64) NOT NULL,
    currency CHAR(3) NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    fee NUMERIC(19, 2) NOT NULL DEFAULT 0,
    purpose VARCHAR(200),
    status VARCHAR(32) NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT transactions_amount_positive CHECK (amount > 0),
    CONSTRAINT transactions_fee_non_negative CHECK (fee >= 0)
);

CREATE INDEX banking_transactions_customer_created_idx
    ON banking_transactions(customer_id, created_at DESC);
CREATE UNIQUE INDEX banking_transactions_customer_request_unique
    ON banking_transactions(customer_id, client_request_id);

CREATE TABLE receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    transaction_id UUID NOT NULL REFERENCES banking_transactions(id) ON DELETE RESTRICT,
    template_version VARCHAR(40) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    content_type VARCHAR(100) NOT NULL DEFAULT 'application/pdf',
    pdf_data BYTEA NOT NULL,
    pdf_sha256 CHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT receipts_pdf_not_empty CHECK (octet_length(pdf_data) > 0),
    CONSTRAINT receipts_one_per_transaction UNIQUE (transaction_id)
);

CREATE INDEX receipts_customer_created_idx ON receipts(customer_id, created_at DESC);

CREATE TABLE message_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    channel VARCHAR(16) NOT NULL,
    kind VARCHAR(40) NOT NULL,
    destination_masked VARCHAR(320) NOT NULL,
    provider_message_id VARCHAR(255),
    status VARCHAR(32) NOT NULL,
    error_code VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX message_deliveries_customer_created_idx
    ON message_deliveries(customer_id, created_at DESC);
