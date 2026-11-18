WITH normalized_payments AS (

    SELECT
        NULLIF(TRIM(payment_id), '') AS payment_id,

        NULLIF(TRIM(order_id), '') AS order_id,

        NULLIF(TRIM(payment_ts), '') AS payment_ts,

        NULLIF(UPPER(TRIM(payment_method)), '')
            AS payment_method,

        NULLIF(UPPER(TRIM(payment_status)), '')
            AS payment_status,

        NULLIF(TRIM(paid_amount), '') AS paid_amount

    FROM `mahesh2726.ecommerce01_staging.payments_stg`
),

typed_payments AS (

    SELECT
        payment_id,
        order_id,

        SAFE_CAST(payment_ts AS TIMESTAMP)
            AS payment_ts,

        payment_method,
        payment_status,

        SAFE_CAST(paid_amount AS NUMERIC)
            AS paid_amount

    FROM normalized_payments
)

SELECT *
FROM typed_payments;

SELECT
    payment_id,
    COUNT(*) AS payment_count

FROM typed_payments

GROUP BY payment_id

HAVING COUNT(*) > 1;

SELECT
    COUNTIF(payment_id IS NULL) AS null_payment_id,
    COUNTIF(order_id IS NULL) AS null_order_id,
    COUNTIF(payment_ts IS NULL) AS null_payment_ts,
    COUNTIF(payment_method IS NULL) AS null_payment_method,
    COUNTIF(payment_status IS NULL) AS null_payment_status,
    COUNTIF(paid_amount IS NULL) AS null_paid_amount

FROM typed_payments;

SELECT

    COUNTIF(paid_amount < 0)
        AS invalid_paid_amount,

    COUNTIF(
        payment_status NOT IN (
            'SUCCESS',
            'FAILED',
            'PENDING'
        )
    ) AS invalid_payment_status

FROM typed_payments;

SELECT
    COUNT(*) AS invalid_order_reference_count

FROM typed_payments p

WHERE p.order_id IS NOT NULL

AND NOT EXISTS (

    SELECT 1

    FROM `mahesh2726.ecommerce01_staging.orders_stg` o

    WHERE TRIM(o.order_id) = p.order_id
);