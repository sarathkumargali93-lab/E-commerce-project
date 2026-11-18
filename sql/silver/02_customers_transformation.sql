WITH normalized_customers AS (

    SELECT
        NULLIF(TRIM(customer_id), '') AS customer_id,

        NULLIF(TRIM(customer_name), '') AS customer_name,

        NULLIF(LOWER(TRIM(email)), '') AS email,

        NULLIF(UPPER(TRIM(city)), '') AS city,

        NULLIF(UPPER(TRIM(state)), '') AS state,

        NULLIF(TRIM(created_at), '') AS created_at,

        NULLIF(UPPER(TRIM(is_active)), '') AS is_active

    FROM `mahesh2726.ecommerce01_staging.customers_stg`
),

typed_customers AS (

    SELECT
        customer_id,
        customer_name,
        email,
        city,
        state,

        SAFE_CAST(created_at AS TIMESTAMP) AS created_at,

        CASE
            WHEN is_active = 'Y' THEN TRUE
            WHEN is_active = 'N' THEN FALSE
            ELSE NULL
        END AS is_active

    FROM normalized_customers
)

SELECT *
FROM typed_customers;

-- Duplicate validation

SELECT
    customer_id,
    COUNT(*) AS customer_count

FROM typed_customers

GROUP BY customer_id

HAVING COUNT(*) > 1;

-- NULL validation

SELECT
    COUNTIF(customer_id IS NULL) AS null_customer_id,
    COUNTIF(customer_name IS NULL) AS null_customer_name,
    COUNTIF(email IS NULL) AS null_email,
    COUNTIF(city IS NULL) AS null_city,
    COUNTIF(state IS NULL) AS null_state,
    COUNTIF(created_at IS NULL) AS null_created_at,
    COUNTIF(is_active IS NULL) AS null_is_active

FROM typed_customers;

-- Business rule validation

SELECT

    COUNTIF(
        created_at > CURRENT_TIMESTAMP()
    ) AS future_created_at,

    COUNTIF(
        email IS NOT NULL
        AND NOT REGEXP_CONTAINS(
            email,
            r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
        )
    ) AS invalid_email

FROM typed_customers;

SELECT
    COUNTIF(
        is_active IS NOT NULL
        AND is_active NOT IN ('Y', 'N')
    ) AS invalid_is_active

FROM normalized_customers;