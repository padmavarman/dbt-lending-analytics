-- Fact: Payment transactions
-- Tracks individual payment events for cash flow and delinquency analysis

{{
    config(
        materialized='incremental',
        unique_key='payment_id',
        incremental_strategy='merge'
    )
}}

WITH payments AS (
    SELECT * FROM {{ ref('stg_payments') }}

    {% if is_incremental() %}
    WHERE loaded_at > (SELECT MAX(loaded_at) FROM {{ this }})
    {% endif %}
)

SELECT
    payment_id,
    loan_id,
    payment_date,
    payment_amount,
    principal_amount,
    interest_amount,
    late_fee_amount,
    outstanding_balance,
    payment_classification,
    payment_status,
    loaded_at

FROM payments
