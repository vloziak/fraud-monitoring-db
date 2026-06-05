-- Procedures - йдеш і виконуєш дію, ніякої відповіді не повертаєш
-- CALL freeze_account(1);

-- CREATE FRAUD ALERT
CREATE OR REPLACE PROCEDURE create_fraud_alert(p_transaction_id BIGINT,p_reason TEXT,p_risk_score INT)
    LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO fraud_alerts (transaction_id, reason, risk_score, alert_status)
    VALUES (p_transaction_id, p_reason, p_risk_score, 'OPEN');
END;
$$;


-- FREEZE ACCOUNT
CREATE OR REPLACE PROCEDURE freeze_account(p_account_id BIGINT)
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE accounts
    SET status = 'FROZEN'
    WHERE account_id = p_account_id;

    UPDATE cards
    SET status = 'BLOCKED'
    WHERE account_id = p_account_id;
END;
$$;


-- PROCESS TRANSACTION
CREATE OR REPLACE PROCEDURE process_transaction(p_transaction_id BIGINT)
    LANGUAGE plpgsql
AS $$
DECLARE v_country CHAR(2);
        v_amount NUMERIC;
BEGIN
    SELECT merchant_country, amount
    INTO v_country, v_amount
    FROM transactions
    WHERE transaction_id = p_transaction_id;

    IF is_high_risk_country(v_country) OR v_amount > 30000 THEN
        UPDATE transactions
        SET status = 'FLAGGED'
        WHERE transaction_id = p_transaction_id;
    ELSE
        UPDATE transactions
        SET status = 'APPROVED'
        WHERE transaction_id = p_transaction_id;
    END IF;
END;
$$;


-- BLOCK CARD
CREATE OR REPLACE PROCEDURE block_card(p_card_id BIGINT)
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE cards
    SET status = 'BLOCKED'
    WHERE card_id = p_card_id;
END;
$$;


-- DECLINE TRANSACTION
CREATE OR REPLACE PROCEDURE decline_transaction(p_transaction_id BIGINT)
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE transactions
    SET status = 'DECLINED'
    WHERE transaction_id = p_transaction_id;
END;
$$;

