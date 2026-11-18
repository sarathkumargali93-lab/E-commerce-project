WITH normalized_products AS (

    SELECT
        NULLIF(TRIM(product_id), '') AS product_id,

        NULLIF(TRIM(product_name), '') AS product_name,

        NULLIF(UPPER(TRIM(category)), '') AS category,

        NULLIF(TRIM(unit_price), '') AS unit_price,

        NULLIF(TRIM(updated_at), '') AS updated_at,

        NULLIF(UPPER(TRIM(is_active)), '') AS is_active

    FROM `mahesh2726.ecommerce01_staging.products_stg`
),

typed_products AS (

    SELECT
        product_id,
        product_name,
        category,

        SAFE_CAST(unit_price AS NUMERIC)
            AS unit_price,

        SAFE_CAST(updated_at AS TIMESTAMP)
            AS updated_at,

        CASE
            WHEN is_active = 'Y' THEN TRUE
            WHEN is_active = 'N' THEN FALSE
            ELSE NULL
        END AS is_active

    FROM normalized_products
)

SELECT *
FROM typed_products;

SELECT
    product_id,
    COUNT(*) AS product_count

FROM typed_products

GROUP BY product_id

HAVING COUNT(*) > 1;

SELECT
    COUNTIF(product_id IS NULL) AS null_product_id,
    COUNTIF(product_name IS NULL) AS null_product_name,
    COUNTIF(category IS NULL) AS null_category,
    COUNTIF(unit_price IS NULL) AS null_unit_price,
    COUNTIF(updated_at IS NULL) AS null_updated_at,
    COUNTIF(is_active IS NULL) AS null_is_active

FROM typed_products;

SELECT
    COUNTIF(unit_price < 0)
        AS invalid_unit_price,

    COUNTIF(updated_at > CURRENT_TIMESTAMP())
        AS future_updated_at

FROM typed_products;