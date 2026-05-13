-- Dimension: Borrower profiles with risk and income segmentation
-- Used for customer segmentation, product penetration, and sales intelligence

WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

loan_history AS (
    SELECT
        member_id,
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_borrowed,
        AVG(int_rate) AS avg_interest_rate,
        MIN(issue_date) AS first_loan_date,
        MAX(issue_date) AS latest_loan_date,
        COUNT(CASE WHEN loan_status_category = 'DEFAULT' THEN 1 END) AS default_count,
        COUNT(CASE WHEN loan_status_category = 'CHARGED_OFF' THEN 1 END) AS chargeoff_count,
        COUNT(CASE WHEN loan_status_category = 'PERFORMING' THEN 1 END) AS performing_count
    FROM {{ ref('stg_loans') }}
    GROUP BY member_id
),

enriched AS (
    SELECT
        c.member_id,
        c.employment_title,
        c.emp_length_years,
        c.home_ownership,
        c.annual_income,
        c.income_tier,
        c.verification_status,
        c.zip_code,
        c.state,
        c.credit_history_start_date,
        c.open_accounts,
        c.public_records,
        c.revolving_balance,
        c.revolving_utilization,
        c.total_accounts,
        c.application_type,

        -- Loan history metrics
        COALESCE(lh.total_loans, 0) AS total_loans,
        COALESCE(lh.total_borrowed, 0) AS total_borrowed,
        lh.avg_interest_rate,
        lh.first_loan_date,
        lh.latest_loan_date,
        COALESCE(lh.default_count, 0) AS default_count,
        COALESCE(lh.chargeoff_count, 0) AS chargeoff_count,
        COALESCE(lh.performing_count, 0) AS performing_count,

        -- Risk classification
        CASE
            WHEN COALESCE(lh.default_count, 0) + COALESCE(lh.chargeoff_count, 0) > 0 THEN 'HIGH_RISK'
            WHEN c.public_records > 0 OR c.revolving_utilization > 80 THEN 'MEDIUM_RISK'
            WHEN c.revolving_utilization <= 30 AND COALESCE(lh.performing_count, 0) > 0 THEN 'LOW_RISK'
            ELSE 'UNSCORED'
        END AS risk_segment,

        -- Customer lifetime value proxy
        COALESCE(lh.total_borrowed, 0) * COALESCE(lh.avg_interest_rate, 0) / 100 AS estimated_lifetime_interest

    FROM customers c
    LEFT JOIN loan_history lh ON c.member_id = lh.member_id
)

SELECT * FROM enriched
