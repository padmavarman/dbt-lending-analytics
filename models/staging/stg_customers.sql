-- Staging: Clean and enrich customer demographic data
-- Derives income tiers and credit profile segments

WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_customers') }}
),

cleaned AS (
    SELECT
        member_id,
        INITCAP(TRIM(emp_title)) AS employment_title,

        CASE
            WHEN emp_length = '< 1 year' THEN 0
            WHEN emp_length = '1 year' THEN 1
            WHEN emp_length = '10+ years' THEN 10
            WHEN emp_length IS NULL THEN NULL
            ELSE CAST(REPLACE(REPLACE(emp_length, ' years', ''), ' year', '') AS INTEGER)
        END AS emp_length_years,

        UPPER(TRIM(home_ownership)) AS home_ownership,
        annual_inc AS annual_income,

        -- Income segmentation for product penetration analysis
        CASE
            WHEN annual_inc < 30000 THEN 'LOW'
            WHEN annual_inc >= 30000 AND annual_inc < 60000 THEN 'LOWER_MIDDLE'
            WHEN annual_inc >= 60000 AND annual_inc < 100000 THEN 'UPPER_MIDDLE'
            WHEN annual_inc >= 100000 AND annual_inc < 200000 THEN 'HIGH'
            WHEN annual_inc >= 200000 THEN 'ULTRA_HIGH'
            ELSE 'UNKNOWN'
        END AS income_tier,

        UPPER(TRIM(verification_status)) AS verification_status,
        zip_code,
        addr_state AS state,
        earliest_cr_line AS credit_history_start_date,
        open_acc AS open_accounts,
        pub_rec AS public_records,
        revol_bal AS revolving_balance,
        revol_util AS revolving_utilization,
        total_acc AS total_accounts,
        UPPER(TRIM(application_type)) AS application_type,
        loaded_at

    FROM source
    WHERE member_id IS NOT NULL
)

SELECT * FROM cleaned
