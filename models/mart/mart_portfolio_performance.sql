-- Mart: Portfolio Performance Over Time
-- Monthly cohort analysis for revenue trending, vintage analysis, and KPI tracking
-- Powers executive dashboards and quarterly business reviews

WITH loans AS (
    SELECT * FROM {{ ref('fct_loan_originations') }}
),

monthly_cohorts AS (
    SELECT
        TO_CHAR(issue_date, 'YYYY-MM') AS origination_month,
        EXTRACT(YEAR FROM issue_date) AS origination_year,
        EXTRACT(QUARTER FROM issue_date) AS origination_quarter,
        grade,
        loan_purpose,

        -- Volume
        COUNT(*) AS loans_originated,
        SUM(loan_amount) AS total_originated_volume,
        AVG(loan_amount) AS avg_loan_size,

        -- Pricing
        AVG(interest_rate) AS avg_interest_rate,
        AVG(debt_to_income) AS avg_dti,

        -- Performance
        SUM(total_payment) AS total_collections,
        SUM(total_principal_received) AS total_principal_collected,
        SUM(total_interest_received) AS total_interest_collected,
        SUM(net_revenue) AS total_net_revenue,

        -- Defaults
        SUM(CASE WHEN is_default THEN 1 ELSE 0 END) AS total_defaults,
        SUM(CASE WHEN is_default THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*), 0) AS default_rate,
        SUM(loss_amount) AS total_losses,

        -- Net yield
        (SUM(net_revenue) - SUM(loss_amount)) * 1.0 / NULLIF(SUM(loan_amount), 0) AS net_yield,

        -- Month-over-month growth
        LAG(COUNT(*)) OVER (ORDER BY TO_CHAR(issue_date, 'YYYY-MM')) AS prev_month_loans,
        (COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY TO_CHAR(issue_date, 'YYYY-MM'))) * 1.0
            / NULLIF(LAG(COUNT(*)) OVER (ORDER BY TO_CHAR(issue_date, 'YYYY-MM')), 0) AS mom_growth_rate

    FROM loans
    GROUP BY 1, 2, 3, 4, 5
)

SELECT * FROM monthly_cohorts
ORDER BY origination_month DESC
