-- Mart: Product Penetration Analysis
-- Measures how each loan product performs across customer segments and regions
-- Directly supports product strategy and cross-sell/up-sell decisions

WITH loans AS (
    SELECT * FROM {{ ref('fct_loan_originations') }}
),

borrowers AS (
    SELECT * FROM {{ ref('dim_borrowers') }}
),

product_segment AS (
    SELECT
        l.grade,
        l.loan_purpose,
        l.term_months,
        b.income_tier,
        b.risk_segment,
        l.state,

        -- Volume metrics
        COUNT(*) AS total_loans,
        COUNT(DISTINCT l.member_id) AS unique_borrowers,
        SUM(l.loan_amount) AS total_volume,
        AVG(l.loan_amount) AS avg_loan_size,

        -- Penetration rate: what % of borrowers in this segment use this product
        COUNT(DISTINCT l.member_id) * 1.0 / NULLIF(
            SUM(COUNT(DISTINCT l.member_id)) OVER (PARTITION BY b.income_tier, l.state), 0
        ) AS product_penetration_rate,

        -- Performance metrics
        AVG(l.interest_rate) AS avg_interest_rate,
        SUM(l.net_revenue) AS total_net_revenue,
        AVG(l.net_revenue) AS avg_revenue_per_loan,

        -- Risk metrics
        SUM(CASE WHEN l.is_default THEN 1 ELSE 0 END) AS default_count,
        SUM(CASE WHEN l.is_default THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*), 0) AS default_rate,
        SUM(l.loss_amount) AS total_losses,

        -- Profitability
        SUM(l.net_revenue) - SUM(l.loss_amount) AS net_profit

    FROM loans l
    LEFT JOIN borrowers b ON l.member_id = b.member_id
    GROUP BY 1, 2, 3, 4, 5, 6
)

SELECT
    *,
    -- Product profitability ranking within each segment
    RANK() OVER (
        PARTITION BY income_tier, state
        ORDER BY net_profit DESC
    ) AS profitability_rank

FROM product_segment
