-- Views

-- 1. Customers with theirs accounts
CREATE OR REPLACE VIEW vw_customer_accounts AS
SELECT c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    a.account_id,
    a.account_number,
    a.currency,
    a.balance,
    a.status
FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id;


-- 2. Recent transactions for past 7 days
CREATE OR REPLACE VIEW vw_recent_transactions AS
SELECT t.transaction_id,
    t.amount,
    t.currency,
    t.status,
    t.merchant_country,
    t.transaction_at,
    a.account_number
FROM transactions t
         JOIN accounts a ON t.account_id = a.account_id
WHERE t.transaction_at >= NOW() - INTERVAL '7 days';


-- 3. Only flagged transactions
CREATE OR REPLACE VIEW vw_flagged_transactions AS
SELECT t.transaction_id,
    t.amount,
    t.currency,
    t.merchant_country,
    t.transaction_at,
    c.first_name,
    c.last_name,
    c.email
FROM transactions t
         JOIN accounts a ON t.account_id = a.account_id
         JOIN customers c ON a.customer_id = c.customer_id
WHERE t.status = 'FLAGGED';


-- 4. Shows every client and their risks
CREATE OR REPLACE VIEW vw_customer_risk_profile AS
SELECT c.customer_id,c.first_name,c.last_name,
    COUNT(t.transaction_id) AS total_transactions,
    COUNT(CASE WHEN t.status = 'FLAGGED' THEN 1 END) AS flagged_count,
    COUNT(fa.alert_id) AS total_alerts
FROM customers c
         LEFT JOIN accounts a ON c.customer_id = a.customer_id -- Left because all customers even if they do not have risk
         LEFT JOIN transactions t ON a.account_id = t.account_id
         LEFT JOIN fraud_alerts fa ON t.transaction_id = fa.transaction_id
GROUP BY c.customer_id, c.first_name, c.last_name;