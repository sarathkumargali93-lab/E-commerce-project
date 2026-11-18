CREATE SCHEMA IF NOT EXISTS
`mahesh2726.ecommerce01_history`;


CREATE OR REPLACE TABLE
`mahesh2726.ecommerce01_history.orders_history`

PARTITION BY order_date

CLUSTER BY customer_id, order_status

AS


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
),

valid_orders AS (

    SELECT o.*

    FROM typed_orders o

    WHERE
        order_id IS NOT NULL
        AND customer_id IS NOT NULL
        AND product_id IS NOT NULL
        AND quantity IS NOT NULL
        AND unit_price IS NOT NULL
        AND order_ts IS NOT NULL

        AND quantity > 0
        AND unit_price >= 0

        AND order_status IN (
            'CREATED',
            'SHIPPED',
            'DELIVERED',
            'CANCELLED'
        )

        AND EXISTS (
            SELECT 1
            FROM `mahesh2726.ecommerce01_staging.customers_stg` c
            WHERE TRIM(c.customer_id) = o.customer_id
        )

        AND EXISTS (
            SELECT 1
            FROM `mahesh2726.ecommerce01_staging.products_stg` p
            WHERE TRIM(p.product_id) = o.product_id
        )
),

customers AS (

    SELECT
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(customer_name), '') AS customer_name,
        NULLIF(LOWER(TRIM(email)), '') AS email,
        NULLIF(UPPER(TRIM(city)), '') AS city,
        NULLIF(UPPER(TRIM(state)), '') AS state,

        SAFE_CAST(
            NULLIF(TRIM(created_at), '')
            AS TIMESTAMP
        ) AS customer_created_at,

        CASE
            WHEN UPPER(TRIM(is_active)) = 'Y' THEN TRUE
            WHEN UPPER(TRIM(is_active)) = 'N' THEN FALSE
            ELSE NULL
        END AS customer_is_active

    FROM `mahesh2726.ecommerce01_staging.customers_stg`
),

products AS (

    SELECT
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(product_name), '') AS product_name,
        NULLIF(UPPER(TRIM(category)), '') AS category,

        SAFE_CAST(
            NULLIF(TRIM(unit_price), '')
            AS NUMERIC
        ) AS product_master_price,

        CASE
            WHEN UPPER(TRIM(is_active)) = 'Y' THEN TRUE
            WHEN UPPER(TRIM(is_active)) = 'N' THEN FALSE
            ELSE NULL
        END AS product_is_active

    FROM `mahesh2726.ecommerce01_staging.products_stg`
),

payments AS (

    SELECT
        NULLIF(TRIM(payment_id), '') AS payment_id,
        NULLIF(TRIM(order_id), '') AS order_id,

        SAFE_CAST(
            NULLIF(TRIM(payment_ts), '')
            AS TIMESTAMP
        ) AS payment_ts,

        NULLIF(
            UPPER(TRIM(payment_method)),
            ''
        ) AS payment_method,

        NULLIF(
            UPPER(TRIM(payment_status)),
            ''
        ) AS payment_status,

        SAFE_CAST(
            NULLIF(TRIM(paid_amount), '')
            AS NUMERIC
        ) AS paid_amount

    FROM `mahesh2726.ecommerce01_staging.payments_stg`
),

enriched_orders AS (

    SELECT
        o.order_id,

        o.customer_id,
        c.customer_name,
        c.email,
        c.city,
        c.state,
        c.customer_created_at,
        c.customer_is_active,

        o.product_id,
        p.product_name,
        p.category,
        p.product_master_price,
        p.product_is_active,

        o.quantity,
        o.unit_price,

        o.order_ts,
        o.order_status,
        o.source_system,

        pay.payment_id,
        pay.payment_ts,
        pay.payment_method,
        pay.payment_status,
        pay.paid_amount

    FROM valid_orders o

    LEFT JOIN customers c
        ON o.customer_id = c.customer_id

    LEFT JOIN products p
        ON o.product_id = p.product_id

    LEFT JOIN payments pay
        ON o.order_id = pay.order_id
),

derived_orders AS (

    SELECT
        *,

        DATE(order_ts)
            AS order_date,

        quantity * unit_price
            AS order_amount,

        COALESCE(paid_amount, 0)
        - (quantity * unit_price)
            AS payment_difference

    FROM enriched_orders
)

SELECT
    *,

    CURRENT_DATE() AS batch_date,

    CURRENT_TIMESTAMP() AS processed_at

FROM derived_orders;