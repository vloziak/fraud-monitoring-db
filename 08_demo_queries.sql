-- test func
SELECT get_customer_age(1);

SELECT mask_card_number('hash_001');

SELECT is_high_risk_country('RU');

SELECT is_high_risk_country('UA');

SELECT get_account_balance(1);

SELECT is_card_expired(3);

SELECT is_card_expired(1);

SELECT get_transaction_count_today(1);


-- test procedures
CALL freeze_account(1);
SELECT status FROM accounts WHERE account_id = 1;
SELECT status FROM cards WHERE account_id = 1;

CALL block_card(4);
SELECT card_id, status FROM cards WHERE card_id = 4;


CALL decline_transaction(2);
SELECT transaction_id, status FROM transactions WHERE transaction_id = 2;


-- test triggers
INSERT INTO transactions (account_id, card_id, amount, currency, merchant_category, merchant_country)
VALUES (3, 3, 100, 'UAH', 'groceries', 'UA');

SELECT transaction_id, amount, merchant_country, status FROM transactions ORDER BY transaction_id DESC LIMIT 3;


INSERT INTO transactions (account_id, card_id, amount, currency, merchant_category, merchant_country)
VALUES (3, 3, 500, 'UAH', 'electronics', 'RU');

SELECT transaction_id, amount, merchant_country, status FROM transactions ORDER BY transaction_id DESC LIMIT 3;


SELECT * FROM transaction_status_history ORDER BY changed_at DESC LIMIT 5;

DELETE FROM customers WHERE customer_id = 2;


-- test views
SELECT * FROM vw_flagged_transactions;

SELECT * FROM vw_customer_accounts;

SELECT * FROM vw_recent_transactions;

SELECT * FROM vw_customer_risk_profile ORDER BY flagged_count DESC;


-- test materialized view
SELECT * FROM mv_country_risk_summary; -- nothing here

REFRESH MATERIALIZED VIEW mv_country_risk_summary;
SELECT * FROM mv_country_risk_summary; -- data appeared


-- just queries
SELECT status, COUNT(*) AS total FROM transactions GROUP BY status;

SELECT * FROM vw_customer_risk_profile
ORDER BY flagged_count DESC;

SELECT card_id, card_number_hash, expiration_date, is_card_expired(card_id) AS expired
FROM cards
ORDER BY expiration_date;

SELECT card_id, mask_card_number(card_number_hash) AS masked_number
FROM cards;
