-- Fact: Loan originations — the core transaction table
-- Each row = one loan, enriched with product and borrower keys
-- Incremental: appends new loans based on loaded_at timestamp

{{
    config(
        materialized='incremental',
        unique_key='loan_id',
        incremental_strategy='merge'
    )
}}

WITH loans AS (
    SELECT * FROM {{ ref('stg_loans') }}

    {% if is_incremental() %}
    WHERE loaded_at > (SELECT MAX(loaded_at) FROM {{ this }})
    {% endif %}
),

enriched AS (
    SELECT
        l.loan_id,
        l.member_id,
        l.issue_date,
        l.loan_amnt AS loan_amount,
        l.funded_amnt AS funded_amount,
        l.funded_amnt_inv AS investor_funded_amount,
        l.term_months,
        l.int_rate AS interest_rate,
        l.installment,
        l.grade,
        l.sub_grade,
        l.loan_purpose,
        l.loan_status_category,
        l.loan_status_raw,
        l.home_ownership,
        l.annual_inc AS annual_income,
        l.dti AS debt_to_income,
        l.addr_state AS state,
        l.zip_code,

        -- Financial performance metrics
        l.total_pymnt AS total_payment,
        l.total_rec_prncp AS total_principal_received,
        l.total_rec_int AS total_interest_received,
        l.total_rec_late_fee AS total_late_fees,
        l.recoveries,
        l.collection_recovery_fee,

        -- Derived: net revenue per loan
        (l.total_rec_int + l.total_rec_late_fee + l.recoveries - l.collection_recovery_fee) AS net_revenue,

        -- Derived: loss given default
        CASE
            WHEN l.loan_status_category IN ('DEFAULT', 'CHARGED_OFF')
            THEN l.loan_amnt - l.total_pymnt
            ELSE 0
        END AS loss_amount,

        -- Derived: is_default flag
        CASE
            WHEN l.loan_status_category IN ('DEFAULT', 'CHARGED_OFF') THEN TRUE
            ELSE FALSE
        END AS is_default,

        l.last_payment_date,
        l.last_payment_amount,
        l.loaded_at

    FROM loans l
)

SELECT * FROM enriched
