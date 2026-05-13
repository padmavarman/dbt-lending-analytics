-- Test: Ensure no loans have negative amounts
-- Data integrity check critical for financial reporting

SELECT
    loan_id,
    loan_amnt
FROM {{ ref('stg_loans') }}
WHERE loan_amnt < 0
