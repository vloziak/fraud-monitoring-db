-- Table Creation

-- droping tables if they already exist (for re-running the script)
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS fraud_alerts CASCADE;
DROP TABLE IF EXISTS fraud_rules CASCADE;
DROP TABLE IF EXISTS transaction_status_history CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS cards CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- 1. Customers
CREATE TABLE customers (
    customer_id  BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    birth_date DATE NOT NULL,
    country_code CHAR(2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- обмеження: назва тип_обмеження (умова)
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT chk_customers_email CHECK (email LIKE '%@%'),
    CONSTRAINT chk_customers_country CHECK (LENGTH(country_code) = 2),
    CONSTRAINT chk_customers_birth_date CHECK (birth_date < CURRENT_DATE)
);

-- 2. Accounts
CREATE TABLE accounts (
    account_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    account_number VARCHAR(34) NOT NULL,
    currency CHAR(3) NOT NULL,
    balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    opened_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_accounts_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT uq_accounts_number UNIQUE (account_number),
    CONSTRAINT chk_accounts_balance CHECK (balance >= 0),
    CONSTRAINT chk_accounts_currency CHECK (currency IN ('UAH', 'USD', 'EUR')),
    CONSTRAINT chk_accounts_status CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED'))
);

-- 3. Cards
CREATE TABLE cards(
    card_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL,
    card_number_hash VARCHAR(64) NOT NULL,
    card_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    expiration_date DATE NOT NULL,

    CONSTRAINT fk_cards_account FOREIGN KEY (account_id) REFERENCES accounts (account_id),
    CONSTRAINT chk_cards_type CHECK (card_type IN ('DEBIT', 'CREDIT')),
    CONSTRAINT chk_cards_status CHECK (status IN ('ACTIVE', 'BLOCKED', 'EXPIRED')),
    CONSTRAINT chk_cards_expiry CHECK (expiration_date > '2000-01-01')
);

-- 4. Transactions
CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL,
    card_id BIGINT,
    amount NUMERIC(15, 2) NOT NULL,
    currency CHAR(3) NOT NULL,
    merchant_category VARCHAR(100),
    merchant_country CHAR(2),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    risk_score INT NOT NULL DEFAULT 0,
    transaction_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_transactions_account FOREIGN KEY (account_id) REFERENCES accounts (account_id),
    CONSTRAINT fk_transactions_card FOREIGN KEY (card_id) REFERENCES cards (card_id),
    CONSTRAINT chk_transactions_amount CHECK (amount > 0),
    CONSTRAINT chk_transactions_currency CHECK (currency IN ('UAH', 'USD', 'EUR')),
    CONSTRAINT chk_transactions_status CHECK (status IN ('PENDING', 'APPROVED', 'DECLINED', 'FLAGGED')),
    CONSTRAINT chk_transactions_risk CHECK (risk_score BETWEEN 0 AND 100)
);

-- 5. Transaction status history

CREATE TABLE transaction_status_history (
    history_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    changed_by VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,

    CONSTRAINT fk_tsh_transaction FOREIGN KEY (transaction_id) REFERENCES transactions (transaction_id)
);

-- 6. Fraud rules

CREATE TABLE fraud_rules(
    rule_id BIGSERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    rule_type VARCHAR(50) NOT NULL,
    threshold_value INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_fraud_rules_name UNIQUE (rule_name),
    CONSTRAINT chk_fraud_rules_type CHECK (rule_type IN ('AMOUNT', 'FREQUENCY', 'COUNTRY', 'TIME')),
    CONSTRAINT chk_fraud_rules_thr CHECK (threshold_value > 0)
);

-- 7. Fraud alerts

CREATE TABLE fraud_alerts(
    alert_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    rule_id BIGINT,
    reason TEXT NOT NULL,
    risk_score INT NOT NULL,
    alert_status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_alerts_transaction FOREIGN KEY (transaction_id) REFERENCES transactions (transaction_id),
    CONSTRAINT fk_alerts_rule FOREIGN KEY (rule_id) REFERENCES fraud_rules (rule_id),
    CONSTRAINT chk_alerts_status CHECK (alert_status IN ('OPEN', 'REVIEWED', 'CLOSED')),
    CONSTRAINT chk_alerts_risk CHECK (risk_score BETWEEN 0 AND 100)
);

-- 8. Audit log

CREATE TABLE audit_log(
    audit_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(10) NOT NULL,
    old_value JSONB, -- для json values
    new_value JSONB,
    changed_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_audit_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT chk_audit_op CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- Indexes

CREATE INDEX idx_accounts_customer_id ON accounts (customer_id);
CREATE INDEX idx_cards_account_id ON cards (account_id);
CREATE INDEX idx_transactions_account_id ON transactions (account_id);
CREATE INDEX idx_transactions_status ON transactions (status);
CREATE INDEX idx_transactions_created_at ON transactions (created_at);
CREATE INDEX idx_fraud_alerts_tx_id ON fraud_alerts (transaction_id);
CREATE INDEX idx_audit_log_table ON audit_log (table_name);
CREATE INDEX idx_audit_log_changed_at ON audit_log (changed_at);