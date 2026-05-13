-- Mart: Customer Segmentation & Sales Intelligence
-- Identifies high-value prospects, cross-sell opportunities, and at-risk accounts
-- Directly supports relationship manager prioritization and sales strategy

WITH borrowers AS (
    SELECT * FROM {{ ref('dim_borrowers') }}
),

loans AS (
    SELECT * FROM {{ ref('fct_loan_originations') }}
),

customer_360 AS (
    SELECT
        b.member_id,
        b.income_tier,
        b.risk_segment,
        b.home_ownership,
        b.state,
        b.annual_income,
        b.emp_length_years,
        b.total_loans,
        b.total_borrowed,
        b.estimated_lifetime_interest,
        b.default_count,

        -- Product diversity: how many different products has this customer used
        COUNT(DISTINCT l.loan_purpose) AS product_diversity,
        COUNT(DISTINCT l.grade) AS grade_diversity,

        -- Recency: days since last loan
        DATEDIFF('day', MAX(l.issue_date), CURRENT_DATE()) AS days_since_last_loan,

        -- Monetary: total revenue generated
        SUM(l.net_revenue) AS total_revenue_generated,
        AVG(l.net_revenue) AS avg_revenue_per_loan,

        -- Behavioral
        AVG(l.interest_rate) AS avg_rate_accepted,
        AVG(l.debt_to_income) AS avg_dti,
        SUM(CASE WHEN l.is_default THEN 1 ELSE 0 END) AS lifetime_defaults

    FROM borrowers b
    LEFT JOIN loans l ON b.member_id = l.member_id
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
),

segmented AS (
    SELECT
        *,

        -- RFM-inspired scoring
        CASE
            WHEN days_since_last_loan <= 180 THEN 3
            WHEN days_since_last_loan <= 365 THEN 2
            ELSE 1
        END AS recency_score,

        CASE
            WHEN total_loans >= 3 THEN 3
            WHEN total_loans = 2 THEN 2
            ELSE 1
        END AS frequency_score,

        CASE
            WHEN total_revenue_generated >= 5000 THEN 3
            WHEN total_revenue_generated >= 1000 THEN 2
            ELSE 1
        END AS monetary_score,

        -- Actionable segment
        CASE
            WHEN total_revenue_generated >= 5000 AND lifetime_defaults = 0 AND product_diversity < 3
                THEN 'HIGH_VALUE_CROSS_SELL'
            WHEN total_revenue_generated >= 1000 AND lifetime_defaults = 0
                THEN 'GROW_RELATIONSHIP'
            WHEN days_since_last_loan > 365 AND lifetime_defaults = 0
                THEN 'REACTIVATION_TARGET'
            WHEN lifetime_defaults > 0
                THEN 'RISK_MANAGEMENT'
            ELSE 'NURTURE'
        END AS sales_action,

        -- Priority flag for relationship managers
        CASE
            WHEN total_revenue_generated >= 5000 AND lifetime_defaults = 0 THEN 'P1_HIGH'
            WHEN total_revenue_generated >= 1000 THEN 'P2_MEDIUM'
            ELSE 'P3_LOW'
        END AS rm_priority

    FROM customer_360
)

SELECT * FROM segmented
