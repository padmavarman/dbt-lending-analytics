# 🏦 Lending Portfolio Analytics — dbt + Snowflake Data Pipeline

An end-to-end analytics engineering project that transforms raw lending data into actionable business intelligence using **dbt (Data Build Tool)** and **Snowflake**. The pipeline ingests loan origination, payment, and customer data, then models it through a staging → dimension → fact → mart architecture to power product penetration analysis, credit risk segmentation, portfolio performance tracking, and sales intelligence.

---

## 📌 Business Problem

Financial institutions need to answer critical questions to drive growth and manage risk:

- **Product Penetration:** Which loan products are underpenetrated in which customer segments and regions?
- **Credit Risk:** Which borrower cohorts have elevated default rates, and how early can we flag them?
- **Portfolio Health:** How are origination volumes, net yield, and default rates trending month-over-month?
- **Sales Intelligence:** Which customers should relationship managers prioritize for cross-sell, reactivation, or risk management?

This project builds the data infrastructure to answer all four — transforming raw transactional data into analytics-ready marts.

---

## 🏗️ Architecture

```
                    ┌──────────────┐
                    │   S3 Bucket  │  (Raw CSVs)
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  Snowflake   │  (Raw Schema)
                    │  raw_loans   │
                    │  raw_payments│
                    │  raw_customers│
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │   STAGING    │  (Views — clean, standardize, classify)
                    │  stg_loans   │
                    │  stg_payments│
                    │  stg_customers│
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
       ┌──────▼─────┐ ┌───▼────┐ ┌─────▼──────┐
       │ DIMENSIONS │ │ FACTS  │ │   MARTS    │
       │dim_borrowers│ │fct_loan│ │mart_product│
       │dim_products │ │fct_pay │ │mart_default│
       │dim_dates    │ │        │ │mart_portfo │
       │dim_geography│ │        │ │mart_cust   │
       └─────────────┘ └────────┘ └────────────┘
```

**Tech Stack:** dbt Core · Snowflake · SQL · S3 · dbt_utils

---

## 📂 Project Structure

```
dbt-lending-analytics/
├── models/
│   ├── staging/              # Views — data cleaning & standardization
│   │   ├── src_lending.yml   # Source definitions with tests
│   │   ├── stg_loans.sql     # Loan status classification, term parsing
│   │   ├── stg_payments.sql  # Payment behavior classification
│   │   └── stg_customers.sql # Income tier segmentation
│   ├── dim/                  # Dimension tables
│   │   ├── dim_borrowers.sql # Risk scoring, CLV proxy, loan history
│   │   ├── dim_loan_products.sql # Product tier & purpose grouping
│   │   ├── dim_dates.sql     # Date spine with fiscal quarters
│   │   └── dim_geography.sql # Regional market segmentation
│   ├── fct/                  # Fact tables (incremental)
│   │   ├── fct_loan_originations.sql # Net revenue, loss, default flags
│   │   └── fct_payments.sql  # Payment transaction events
│   ├── mart/                 # Business-facing analytics layers
│   │   ├── mart_product_penetration.sql  # Penetration rates by segment
│   │   ├── mart_default_analysis.sql     # Risk alerts by cohort
│   │   ├── mart_portfolio_performance.sql # Monthly vintage analysis
│   │   └── mart_customer_segmentation.sql # RFM scoring & sales actions
│   └── schema.yml            # Model documentation & tests
├── macros/
│   └── calculate_net_revenue.sql
├── tests/
│   └── assert_no_negative_loan_amounts.sql
├── snowflake_setup.sql       # Snowflake environment bootstrap
├── dbt_project.yml           # dbt configuration
├── packages.yml              # dbt_utils dependency
├── profiles.yml.example      # Connection template (DO NOT commit real creds)
└── README.md
```

---

## 🔑 Key Models Explained

### Staging Layer (Views)
| Model | What it does |
|---|---|
| `stg_loans` | Parses term strings to integers, classifies loan status into business categories (PERFORMING, WATCH, DELINQUENT, DEFAULT, CHARGED_OFF), standardizes text fields |
| `stg_payments` | Classifies payments as ON_TIME, LATE, or MISSED based on late fee presence |
| `stg_customers` | Segments customers into income tiers (LOW → ULTRA_HIGH), standardizes employment and ownership fields |

### Dimension Layer (Tables)
| Model | What it does |
|---|---|
| `dim_borrowers` | Enriches customer profiles with loan history aggregates, risk classification (LOW/MEDIUM/HIGH), and estimated lifetime interest |
| `dim_loan_products` | Classifies products by tier (PRIME/NEAR_PRIME/SUBPRIME), term, and purpose group (DEBT_MANAGEMENT, HOUSING, etc.) |
| `dim_dates` | Date spine from 2007–2025 with fiscal quarters, week numbers, weekend flags |
| `dim_geography` | Maps states to regions (WEST, SOUTH, NORTHEAST, MIDWEST, MOUNTAIN) |

### Fact Layer (Incremental)
| Model | What it does |
|---|---|
| `fct_loan_originations` | Core transaction table — one row per loan with derived net revenue, loss amount, and default flags. Uses incremental merge strategy. |
| `fct_payments` | Payment-level events with classification. Incremental merge on payment_id. |

### Mart Layer (Tables)
| Model | Business Question |
|---|---|
| `mart_product_penetration` | Which products are underpenetrated in which segments? Calculates penetration rates and profitability rankings per income tier and state. |
| `mart_default_analysis` | Where is risk concentrated? Flags CRITICAL/HIGH/ELEVATED segments based on default rate thresholds and exposure. |
| `mart_portfolio_performance` | How is the book trending? Monthly cohort analysis with MoM growth, net yield, and vintage default rates. |
| `mart_customer_segmentation` | Who should sales prioritize? RFM-inspired scoring with actionable segments: HIGH_VALUE_CROSS_SELL, REACTIVATION_TARGET, RISK_MANAGEMENT. |

---

## 🚀 Setup & Run

### Prerequisites
- Python 3.8+
- Snowflake account
- dbt-core + dbt-snowflake

### Step 1: Clone & Install
```bash
git clone https://github.com/<your-username>/dbt-lending-analytics.git
cd dbt-lending-analytics
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install dbt-snowflake==1.9.0
```

### Step 2: Snowflake Setup
Run `snowflake_setup.sql` in your Snowflake console as ACCOUNTADMIN.

### Step 3: Configure Connection
```bash
# Copy the example profile
cp profiles.yml.example ~/.dbt/profiles.yml
# Edit with your Snowflake account details
```

### Step 4: Load Data
Download the [Lending Club dataset from Kaggle](https://www.kaggle.com/datasets/wordsforthewise/lending-club) and load into the raw tables via Snowflake UI or S3 stage.

### Step 5: Run dbt
```bash
dbt deps          # Install dbt_utils
dbt debug         # Verify connection
dbt run           # Build all models
dbt test          # Run data quality tests
dbt docs generate # Generate documentation
dbt docs serve    # View docs in browser
```

---

## 🧪 Testing

The project includes both schema tests and custom data quality tests:

- **Schema tests:** unique, not_null, accepted_values on all key columns
- **Custom tests:** `assert_no_negative_loan_amounts` — ensures financial data integrity
- **Source freshness:** Configured on all raw tables via `loaded_at` timestamps

Run tests:
```bash
dbt test                    # All tests
dbt test --select staging   # Staging only
dbt test --select mart      # Mart only
```

---

## 📊 Sample Insights This Pipeline Enables

1. **"Debt consolidation loans to UPPER_MIDDLE income borrowers in the NORTHEAST have 2.3x higher penetration than the SOUTH — expand marketing there."**
2. **"Grade E loans with DTI > 25 in the MOUNTAIN region have a 22% default rate — flag as CRITICAL and tighten underwriting."**
3. **"Q3 origination volume grew 8% MoM but net yield dropped 15bps — investigate pricing compression in PRIME products."**
4. **"847 HIGH_VALUE_CROSS_SELL customers have only used debt consolidation — target for home improvement product outreach."**

---

## 📄 License

This project is for educational and portfolio purposes. Dataset sourced from [Lending Club via Kaggle](https://www.kaggle.com/datasets/wordsforthewise/lending-club).
