-- Materialized View

-- статистика по країнах, скільки транзакцій з країни і скільки з них підозрілих
DROP MATERIALIZED VIEW IF EXISTS mv_country_risk_summary;

CREATE MATERIALIZED VIEW mv_country_risk_summary AS
SELECT merchant_country,
    COUNT(transaction_id) AS total_transactions,
    SUM(amount) AS total_amount,
    COUNT(CASE WHEN status = 'FLAGGED' THEN 1 END) AS flagged_count,
    ROUND(AVG(risk_score), 2) AS avg_risk_score,
    is_high_risk_country(merchant_country) AS is_high_risk
FROM transactions
WHERE merchant_country IS NOT NULL
GROUP BY merchant_country
ORDER BY flagged_count DESC;


-- SELECT * FROM mv_country_risk_summary;
-- REFRESH MATERIALIZED VIEW mv_country_risk_summary;
