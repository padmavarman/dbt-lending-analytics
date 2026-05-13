-- Mart: Default Risk & Portfolio Health
-- Surfaces actionable intelligence on credit risk by segment
-- Enables proactive identification of at-risk cohorts

WITH loans AS (
    SELECT * FROM {{ ref('fct_loan_originations') }}
),

borrowers AS (
    SELECT * FROM {{ ref('dim_borrowers') }}
),

risk_analysis AS (
    SELECT
        l.grade,
        l.sub_grade,
        b.income_tier,
        b.risk_segment,
        b.home_ownership,
        l.loan_purpose,
        l.state,

        -- Portfolio composition
        COUNT(*) AS total_loans,
        SUM(l.loan_amount) AS total_exposure,
        AVG(l.loan_amount) AS avg_loan_amount,
        AVG(l.interest_rate) AS avg_interest_rate,
        AVG(l.debt_to_income) AS avg_dti,

        -- Default metrics
        SUM(CASE WHEN l.is_default THEN 1 ELSE 0 END) AS defaults,
        SUM(CASE WHEN l.is_default THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*), 0) AS default_rate,
        SUM(l.loss_amount) AS total_loss,
        AVG(CASE WHEN l.is_default THEN l.loss_amount END) AS avg_loss_given_default,

        -- Recovery metrics
        SUM(l.recoveries) AS total_recoveries,
        SUM(l.recoveries) * 1.0 / NULLIF(SUM(l.loss_amount), 0) AS recovery_rate,

        -- Revenue at risk
        SUM(CASE WHEN l.loan_status_category IN ('WATCH', 'DELINQUENT') THEN l.loan_amount ELSE 0 END) AS at_risk_exposure,
        SUM(CASE WHEN l.loan_status_category IN ('WATCH', 'DELINQUENT') THEN 1 ELSE 0 END) AS at_risk_count

    FROM loans l
    LEFT JOIN borrowers b ON l.member_id = b.member_id
    GROUP BY 1, 2, 3, 4, 5, 6, 7
)

SELECT
    *,
    -- Flag high-risk segments for proactive intervention
    CASE
        WHEN default_rate > 0.20 AND total_exposure > 100000 THEN 'CRITICAL'
        WHEN default_rate > 0.15 THEN 'HIGH'
        WHEN default_rate > 0.10 THEN 'ELEVATED'
        ELSE 'NORMAL'
    END AS risk_alert_level

FROM risk_analysis
