-- Dimension: Geographic segmentation
-- Enables regional product penetration and market expansion analysis

WITH geo AS (
    SELECT DISTINCT
        addr_state AS state_code,
        zip_code,

        -- Regional grouping for market analysis
        CASE
            WHEN addr_state IN ('CA', 'OR', 'WA', 'NV', 'AZ', 'HI', 'AK') THEN 'WEST'
            WHEN addr_state IN ('TX', 'OK', 'AR', 'LA', 'MS', 'AL', 'TN', 'KY', 'WV', 'VA', 'NC', 'SC', 'GA', 'FL') THEN 'SOUTH'
            WHEN addr_state IN ('NY', 'NJ', 'PA', 'CT', 'RI', 'MA', 'VT', 'NH', 'ME', 'DE', 'MD', 'DC') THEN 'NORTHEAST'
            WHEN addr_state IN ('OH', 'MI', 'IN', 'IL', 'WI', 'MN', 'IA', 'MO', 'ND', 'SD', 'NE', 'KS') THEN 'MIDWEST'
            WHEN addr_state IN ('CO', 'UT', 'ID', 'MT', 'WY', 'NM') THEN 'MOUNTAIN'
            ELSE 'OTHER'
        END AS region

    FROM {{ ref('stg_loans') }}
    WHERE addr_state IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['state_code', 'zip_code']) }} AS geo_key,
    *
FROM geo
