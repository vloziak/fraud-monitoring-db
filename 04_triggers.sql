-- Triggers

-- 1. Check transaction
CREATE OR REPLACE FUNCTION trg_check_transaction()
    RETURNS TRIGGER AS $$
BEGIN
    IF is_high_risk_country(NEW.merchant_country) OR NEW.amount > 30000 THEN
        NEW.status := 'FLAGGED';
    ELSE
        NEW.status := 'APPROVED';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_transaction_on_insert
    BEFORE INSERT ON transactions
    FOR EACH ROW
EXECUTE FUNCTION trg_check_transaction();



-- 2. Alert for flaged transaction
CREATE OR REPLACE FUNCTION trg_create_alert_on_flag()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'FLAGGED' AND OLD.status != 'FLAGGED' THEN
        CALL create_fraud_alert(
                NEW.transaction_id,
                'Automatic alert: suspicious transaction',
                65 -- risk score, but for now I assign it manually
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_alert_on_flag
    AFTER UPDATE ON transactions
    FOR EACH ROW
EXECUTE FUNCTION trg_create_alert_on_flag();



-- 3. Writting logs for changed transaction status
CREATE OR REPLACE FUNCTION trg_log_status_change()
    RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO transaction_status_history (transaction_id, old_status, new_status)
        VALUES (NEW.transaction_id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_status_change
    AFTER UPDATE ON transactions
    FOR EACH ROW
EXECUTE FUNCTION trg_log_status_change();



-- 4. Customer deletion protection
CREATE OR REPLACE FUNCTION trg_protect_customer_delete()
    RETURNS TRIGGER AS $$
DECLARE
    v_active_accounts INT;
BEGIN
    SELECT COUNT(*)
    INTO v_active_accounts
    FROM accounts
    WHERE customer_id = OLD.customer_id AND status = 'ACTIVE';

    IF v_active_accounts > 0 THEN
        RAISE EXCEPTION 'You could not delete the customer with an active account. Number of active accounts: %', v_active_accounts;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER protect_customer_delete
    BEFORE DELETE ON customers
    FOR EACH ROW
EXECUTE FUNCTION trg_protect_customer_delete();
