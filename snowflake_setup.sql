-- ============================================================
-- Snowflake Setup for Lending Analytics dbt Project
-- Run these commands in Snowflake as ACCOUNTADMIN
-- ============================================================

-- Step 1: Use admin role
USE ROLE ACCOUNTADMIN;

-- Step 2: Create the `transform` role
CREATE ROLE IF NOT EXISTS TRANSFORM;
GRANT ROLE TRANSFORM TO ROLE ACCOUNTADMIN;

-- Step 3: Create warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WITH WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE;

GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;

-- Step 4: Create the `dbt` user
CREATE USER IF NOT EXISTS dbt
  PASSWORD = 'dbtPassword123'
  LOGIN_NAME = 'dbt'
  MUST_CHANGE_PASSWORD = FALSE
  DEFAULT_WAREHOUSE = 'COMPUTE_WH'
  DEFAULT_ROLE = TRANSFORM
  DEFAULT_NAMESPACE = 'LENDING_ANALYTICS.RAW'
  COMMENT = 'DBT user for lending data transformations';

ALTER USER dbt SET TYPE = LEGACY_SERVICE;
GRANT ROLE TRANSFORM TO USER dbt;

-- Step 5: Create database and schemas
CREATE DATABASE IF NOT EXISTS LENDING_ANALYTICS;
CREATE SCHEMA IF NOT EXISTS LENDING_ANALYTICS.RAW;

-- Step 6: Grant permissions
GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;
GRANT ALL ON DATABASE LENDING_ANALYTICS TO ROLE TRANSFORM;
GRANT ALL ON ALL SCHEMAS IN DATABASE LENDING_ANALYTICS TO ROLE TRANSFORM;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE LENDING_ANALYTICS TO ROLE TRANSFORM;
GRANT ALL ON ALL TABLES IN SCHEMA LENDING_ANALYTICS.RAW TO ROLE TRANSFORM;
GRANT ALL ON FUTURE TABLES IN SCHEMA LENDING_ANALYTICS.RAW TO ROLE TRANSFORM;

-- Step 7: Set defaults
USE WAREHOUSE COMPUTE_WH;
USE DATABASE LENDING_ANALYTICS;
USE SCHEMA RAW;

-- ============================================================
-- Create raw tables
-- ============================================================

-- Loan-level data
CREATE OR REPLACE TABLE raw_loans (
    loan_id INTEGER AUTOINCREMENT,
    member_id INTEGER,
    loan_amnt FLOAT,
    funded_amnt FLOAT,
    funded_amnt_inv FLOAT,
    term STRING,
    int_rate FLOAT,
    installment FLOAT,
    grade STRING,
    sub_grade STRING,
    emp_title STRING,
    emp_length STRING,
    home_ownership STRING,
    annual_inc FLOAT,
    verification_status STRING,
    issue_d DATE,
    loan_status STRING,
    purpose STRING,
    title STRING,
    zip_code STRING,
    addr_state STRING,
    dti FLOAT,
    delinq_2yrs INTEGER,
    earliest_cr_line DATE,
    open_acc INTEGER,
    pub_rec INTEGER,
    revol_bal FLOAT,
    revol_util FLOAT,
    total_acc INTEGER,
    total_pymnt FLOAT,
    total_pymnt_inv FLOAT,
    total_rec_prncp FLOAT,
    total_rec_int FLOAT,
    total_rec_late_fee FLOAT,
    recoveries FLOAT,
    collection_recovery_fee FLOAT,
    last_pymnt_d DATE,
    last_pymnt_amnt FLOAT,
    application_type STRING,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Payment history
CREATE OR REPLACE TABLE raw_payments (
    payment_id INTEGER AUTOINCREMENT,
    loan_id INTEGER,
    payment_date DATE,
    payment_amnt FLOAT,
    principal_amnt FLOAT,
    interest_amnt FLOAT,
    late_fee_amnt FLOAT,
    outstanding_balance FLOAT,
    payment_status STRING,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Customer demographics
CREATE OR REPLACE TABLE raw_customers (
    member_id INTEGER,
    emp_title STRING,
    emp_length STRING,
    home_ownership STRING,
    annual_inc FLOAT,
    verification_status STRING,
    zip_code STRING,
    addr_state STRING,
    earliest_cr_line DATE,
    open_acc INTEGER,
    pub_rec INTEGER,
    revol_bal FLOAT,
    revol_util FLOAT,
    total_acc INTEGER,
    application_type STRING,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- Load data from S3 (update with your S3 bucket path)
-- ============================================================

-- Option A: Load from S3 stage
-- CREATE STAGE lending_stage
--   URL = 's3://your-bucket/lending-data/'
--   CREDENTIALS = (AWS_KEY_ID = '...' AWS_SECRET_KEY = '...');
--
-- COPY INTO raw_loans FROM '@lending_stage/loans.csv'
--   FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-- Option B: Load via Snowflake UI
-- Use Snowflake's "Load Data" wizard to upload CSV files directly

-- Option C: Load from Kaggle CSV using Python (see README for instructions)
