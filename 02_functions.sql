-- Functions - дивишся в систему і повертаєш відповідь, нічого не змінюємо, просто даємо інфо
-- SELECT get_account_balance(1);

-- GET CUSTOMER AGE
CREATE OR REPLACE FUNCTION get_customer_age(p_customer_id BIGINT)
RETURNS INT AS $$
DECLARE v_age INT;
BEGIN
    SELECT DATE_PART('year', AGE(birth_date))
    INTO v_age
    FROM customers
    WHERE customer_id = p_customer_id;

RETURN v_age;
END;
$$ LANGUAGE plpgsql;


-- MASK CARD NUM
CREATE OR REPLACE FUNCTION mask_card_number(p_card_number VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN '**** **** **** ' || RIGHT(p_card_number, 4); -- just the last 4 num of card
END;
$$ LANGUAGE plpgsql;


-- HIGH RISK COUNTRY
CREATE OR REPLACE FUNCTION is_high_risk_country(p_country_code CHAR(2))
RETURNS BOOLEAN AS $$
BEGIN
    RETURN p_country_code = ANY(ARRAY['RU', 'KP', 'IR', 'SY', 'BY']);
END;
$$ LANGUAGE plpgsql;


-- GET ACCOUNT BALANCE
CREATE OR REPLACE FUNCTION get_account_balance(p_account_id BIGINT)
RETURNS NUMERIC AS $$
DECLARE v_balance NUMERIC;
BEGIN
    SELECT balance
    INTO v_balance
    FROM accounts
    WHERE account_id = p_account_id;

    RETURN v_balance;
END;
$$ LANGUAGE plpgsql;


-- CARD EXPIRATION
CREATE OR REPLACE FUNCTION is_card_expired(p_card_id BIGINT)
RETURNS BOOLEAN AS $$
DECLARE v_expiration_date DATE;
BEGIN
    SELECT expiration_date
    INTO v_expiration_date
    FROM cards
    WHERE card_id = p_card_id;

    RETURN v_expiration_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;


-- TRANSACTION COUNT FOR TODAY
CREATE OR REPLACE FUNCTION get_transaction_count_today(p_account_id BIGINT)
RETURNS INT AS $$
DECLARE v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM transactions
    WHERE account_id = p_account_id AND DATE(transaction_at) = CURRENT_DATE;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;