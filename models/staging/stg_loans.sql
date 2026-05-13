-- Staging: Clean and standardize raw loan data
-- Applies business logic for loan status classification and term parsing

WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_loans') }}
),

cleaned AS (
    SELECT
        loan_id,
        member_id,
        loan_amnt,
        funded_amnt,
        funded_amnt_inv,

        -- Parse term to integer months
        CAST(REPLACE(REPLACE(term, ' months', ''), ' ', '') AS INTEGER) AS term_months,

        int_rate,
        installment,
        grade,
        sub_grade,

        -- Standardize employment length
        CASE
            WHEN emp_length = '< 1 year' THEN 0
            WHEN emp_length = '1 year' THEN 1
            WHEN emp_length = '10+ years' THEN 10
            WHEN emp_length IS NULL THEN NULL
            ELSE CAST(REPLACE(REPLACE(emp_length, ' years', ''), ' year', '') AS INTEGER)
        END AS emp_length_years,

        UPPER(TRIM(home_ownership)) AS home_ownership,
        annual_inc,
        UPPER(TRIM(verification_status)) AS verification_status,
        issue_d AS issue_date,

        -- Classify loan status into business categories
        CASE
            WHEN loan_status = 'Fully Paid' THEN 'PERFORMING'
            WHEN loan_status = 'Current' THEN 'PERFORMING'
            WHEN loan_status = 'In Grace Period' THEN 'WATCH'
            WHEN loan_status = 'Late (16-30 days)' THEN 'DELINQUENT'
            WHEN loan_status = 'Late (31-120 days)' THEN 'DELINQUENT'
            WHEN loan_status = 'Default' THEN 'DEFAULT'
            WHEN loan_status = 'Charged Off' THEN 'CHARGED_OFF'
            ELSE 'OTHER'
        END AS loan_status_category,

        loan_status AS loan_status_raw,
        LOWER(TRIM(purpose)) AS loan_purpose,
        zip_code,
        addr_state,
        dti,
        delinq_2yrs,
        earliest_cr_line,
        open_acc,
        pub_rec,
        revol_bal,
        revol_util,
        total_acc,
        total_pymnt,
        total_rec_prncp,
        total_rec_int,
        total_rec_late_fee,
        recoveries,
        collection_recovery_fee,
        last_pymnt_d AS last_payment_date,
        last_pymnt_amnt AS last_payment_amount,
        UPPER(TRIM(application_type)) AS application_type,
        loaded_at

    FROM source
    WHERE loan_amnt IS NOT NULL
      AND loan_amnt > 0
)

SELECT * FROM cleaned
