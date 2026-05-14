# Lending Portfolio Analytics — dbt + Snowflake

A data pipeline that takes messy lending data and turns it into something a business team can actually use. Built with dbt and Snowflake.

The idea is simple: raw loan data goes in, and clean tables come out that answer questions like "where are we underselling?", "where's the risk?", and "who should sales call first?"

## What it does

Raw data (loans, payments, customers) flows through four layers:

- **Staging** — cleans up the data, standardizes fields, classifies loan statuses
- **Dimensions** — borrower profiles with risk scores, product classifications, geography, dates
- **Facts** — one row per loan with net revenue, loss amounts, default flags (incremental)
- **Marts** — the business-facing tables:
  - `mart_product_penetration` — which products are undersold in which segments
  - `mart_default_analysis` — flags high-risk cohorts as CRITICAL/HIGH/ELEVATED
  - `mart_portfolio_performance` — monthly trends, MoM growth, vintage analysis
  - `mart_customer_segmentation` — RFM scoring with actions like CROSS_SELL, REACTIVATION, RISK_MANAGEMENT

## Project structure

```
models/
  staging/       stg_loans, stg_payments, stg_customers
  dim/           dim_borrowers, dim_loan_products, dim_dates, dim_geography
  fct/           fct_loan_originations, fct_payments
  mart/          mart_product_penetration, mart_default_analysis,
                 mart_portfolio_performance, mart_customer_segmentation
macros/          calculate_net_revenue.sql
tests/           assert_no_negative_loan_amounts.sql
```

## Tech

dbt Core, Snowflake, SQL, dbt_utils, S3

## How to run

1. Clone the repo
2. Run `snowflake_setup.sql` in your Snowflake console
3. Download the [Lending Club dataset from Kaggle](https://www.kaggle.com/datasets/wordsforthewise/lending-club) and load it into the raw tables
4. Set up your `profiles.yml` (there's an example file in the repo)
5. Then:

```bash
dbt deps
dbt run
dbt test
```

`dbt docs generate && dbt docs serve` if you want to browse the documentation locally.

## Tests

Schema tests on all key columns (unique, not_null, accepted_values). One custom test that checks for negative loan amounts. Source freshness configured on all raw tables.

## Sample questions this answers

- Debt consolidation loans have 2.3x higher penetration in the Northeast vs the South — worth expanding there
- Grade E loans with high DTI in the Mountain region are defaulting at 22% — needs a closer look
- 847 customers scored as high-value cross-sell targets have only ever used one product

## Data

Lending Club dataset from Kaggle. This project is for learning and portfolio purposes.
