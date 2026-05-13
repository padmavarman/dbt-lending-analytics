-- Dimension: Loan product classification
-- Enables product penetration analysis and cross-sell/up-sell intelligence

WITH loan_products AS (
    SELECT DISTINCT
        grade,
        sub_grade,
        term_months,
        loan_purpose,

        -- Product tier classification
        CASE
            WHEN grade IN ('A', 'B') THEN 'PRIME'
            WHEN grade IN ('C', 'D') THEN 'NEAR_PRIME'
            WHEN grade IN ('E', 'F', 'G') THEN 'SUBPRIME'
            ELSE 'UNCLASSIFIED'
        END AS product_tier,

        -- Term classification
        CASE
            WHEN term_months = 36 THEN 'SHORT_TERM'
            WHEN term_months = 60 THEN 'LONG_TERM'
            ELSE 'OTHER'
        END AS term_category,

        -- Purpose grouping for product strategy
        CASE
            WHEN loan_purpose IN ('debt_consolidation', 'credit_card') THEN 'DEBT_MANAGEMENT'
            WHEN loan_purpose IN ('home_improvement', 'house', 'moving') THEN 'HOUSING'
            WHEN loan_purpose IN ('car', 'major_purchase') THEN 'ASSET_ACQUISITION'
            WHEN loan_purpose IN ('small_business') THEN 'BUSINESS'
            WHEN loan_purpose IN ('medical', 'wedding', 'vacation') THEN 'PERSONAL'
            WHEN loan_purpose IN ('educational') THEN 'EDUCATION'
            ELSE 'OTHER'
        END AS purpose_group

    FROM {{ ref('stg_loans') }}
    WHERE grade IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['grade', 'sub_grade', 'term_months', 'loan_purpose']) }} AS product_key,
    *
FROM loan_products
