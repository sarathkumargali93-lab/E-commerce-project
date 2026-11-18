WITH normalized_orders AS (

    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(quantity), '') AS quantity,
        NULLIF(TRIM(unit_price), '') AS unit_price,
        NULLIF(TRIM(order_ts), '') AS order_ts,
        NULLIF(UPPER(TRIM(order_status)), '') AS order_status,
        NULLIF(UPPER(TRIM(source_system)), '') AS source_system

    FROM `mahesh2726.ecommerce01_staging.orders_stg`
),

typed_orders AS (

    SELECT
        order_id,
        customer_id,
        product_id,

        SAFE_CAST(quantity AS INT64) AS quantity,
        SAFE_CAST(unit_price AS NUMERIC) AS unit_price,
        SAFE_CAST(order_ts AS TIMESTAMP) AS order_ts,

        order_status,
        source_system

    FROM normalized_orders
)

-- Duplicate check
SELECT
    order_id,
    COUNT(*) AS record_count

FROM typed_orders

GROUP BY order_id

HAVING COUNT(*) > 1;

-- NULL validation

SELECT
    COUNTIF(order_id IS NULL) AS null_order_id,
    COUNTIF(customer_id IS NULL) AS null_customer_id,
    COUNTIF(product_id IS NULL) AS null_product_id,
    COUNTIF(quantity IS NULL) AS null_quantity,
    COUNTIF(unit_price IS NULL) AS null_unit_price,
    COUNTIF(order_ts IS NULL) AS null_order_ts,
    COUNTIF(order_status IS NULL) AS null_order_status,
    COUNTIF(source_system IS NULL) AS null_source_system

FROM typed_orders;

-- Business rule validation

SELECT
    COUNTIF(quantity <= 0) AS invalid_quantity,

    COUNTIF(unit_price < 0) AS invalid_unit_price,

    COUNTIF(
        order_status NOT IN (
            'CREATED',
            'SHIPPED',
            'DELIVERED',
            'CANCELLED'
        )
    ) AS invalid_order_status

FROM typed_orders;

-- Customer referential integrity

SELECT
    COUNT(*) AS invalid_customer_reference_count

FROM typed_orders o

WHERE o.customer_id IS NOT NULL

AND NOT EXISTS (

    SELECT 1

    FROM `mahesh2726.ecommerce01_staging.customers_stg` c

    WHERE TRIM(c.customer_id) = o.customer_id
);

-- Product referential integrity

SELECT
    COUNT(*) AS invalid_product_reference_count

FROM typed_orders o

WHERE o.product_id IS NOT NULL

AND NOT EXISTS (

    SELECT 1

    FROM `mahesh2726.ecommerce01_staging.products_stg` p

    WHERE TRIM(p.product_id) = o.product_id
);