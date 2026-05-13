-- Dimension: Date spine for time-series analysis
-- Supports cohort analysis, seasonality, and trend reporting

WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2007-01-01' as date)",
        end_date="cast('2025-12-31' as date)"
    ) }}
),

enriched AS (
    SELECT
        date_day AS date_key,
        EXTRACT(YEAR FROM date_day) AS year,
        EXTRACT(QUARTER FROM date_day) AS quarter,
        EXTRACT(MONTH FROM date_day) AS month,
        EXTRACT(WEEK FROM date_day) AS week_of_year,
        EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,
        TO_CHAR(date_day, 'YYYY-MM') AS year_month,
        TO_CHAR(date_day, 'YYYY') || '-Q' || EXTRACT(QUARTER FROM date_day) AS year_quarter,

        CASE
            WHEN EXTRACT(MONTH FROM date_day) BETWEEN 1 AND 3 THEN 'Q1'
            WHEN EXTRACT(MONTH FROM date_day) BETWEEN 4 AND 6 THEN 'Q2'
            WHEN EXTRACT(MONTH FROM date_day) BETWEEN 7 AND 9 THEN 'Q3'
            WHEN EXTRACT(MONTH FROM date_day) BETWEEN 10 AND 12 THEN 'Q4'
        END AS fiscal_quarter,

        CASE
            WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (0, 6) THEN TRUE
            ELSE FALSE
        END AS is_weekend

    FROM date_spine
)

SELECT * FROM enriched
