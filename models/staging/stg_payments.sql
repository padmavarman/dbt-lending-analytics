-- Staging: Clean and standardize payment transaction data
-- Derives payment classification and running metrics

WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_payments') }}
),

cleaned AS (
    SELECT
        payment_id,
        loan_id,
        payment_date,
        payment_amnt AS payment_amount,
        principal_amnt AS principal_amount,
        interest_amnt AS interest_amount,
        late_fee_amnt AS late_fee_amount,
        outstanding_balance,

        -- Classify payment behavior
        CASE
            WHEN late_fee_amnt > 0 THEN 'LATE'
            WHEN payment_amnt = 0 THEN 'MISSED'
            ELSE 'ON_TIME'
        END AS payment_classification,

        UPPER(TRIM(payment_status)) AS payment_status,
        loaded_at

    FROM source
    WHERE payment_amnt IS NOT NULL
)

SELECT * FROM cleaned
