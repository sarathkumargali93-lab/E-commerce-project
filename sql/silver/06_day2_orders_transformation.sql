WITH normalized_orders AS (
 SELECT
  NULLIF(TRIM(order_id),'') AS order_id,
  NULLIF(TRIM(customer_id),'') AS customer_id,
  NULLIF(TRIM(product_id),'') AS product_id,
  NULLIF(TRIM(quantity),'') AS quantity,
  NULLIF(TRIM(unit_price),'') AS unit_price,
  NULLIF(TRIM(order_ts),'') AS order_ts,
  NULLIF(UPPER(TRIM(order_status)),'') AS order_status,
  NULLIF(UPPER(TRIM(source_system)),'') AS source_system
FROM `mahesh2726.ecommerce01_staging.orders_stg`
),
typed_orders AS(
 SELECT
  order_id,
  customer_id,
  product_id,
  quantity AS quantity_raw,
  unit_price AS unit_price_raw,
  order_ts AS order_ts_raw,
  SAFE_CAST(quantity AS INT64) AS quantity,
  SAFE_CAST(unit_price AS NUMERIC) AS unit_price,
  SAFE_CAST(order_ts AS TIMESTAMP) AS order_ts,
  order_status,
  source_system
 FROM normalized_orders
),
deduplicate_orders AS (
  SELECT * EXCEPT(rn)
  FROM(
    SELECT
      *,
      ROW_NUMBER() OVER(
        PARTITION BY order_id
        ORDER BY order_ts DESC
  ) AS rn FROM typed_orders
  )
  WHERE rn = 1
),
customers_ref AS (
  SELECT DISTINCT NULLIF(TRIM(customer_id),'') AS customer_id
  FROM `mahesh2726.ecommerce01_staging.customers_stg`
),
products_ref AS (
  SELECT DISTINCT NULLIF(TRIM(product_id),'') AS product_id
  FROM `mahesh2726.ecommerce01_staging.products_stg`
),
validated_orders AS (
 SELECT 
  o.*,
  CASE 
   WHEN o.order_id IS NULL THEN 'MISSING_ORDER_ID'
   WHEN O.customer_id IS NULL THEN 'MISSING_CUSTOMER_ID'
   WHEN O.product_id IS NULL THEN 'MISSING_PRODUCT_ID'
   WHEN o.quantity_raw IS NULL THEN 'MISSING_QUANTITY'
   WHEN o.unit_price_raw IS NULL THEN 'MISSING_UNIT_PRICE'
   WHEN O.order_ts_raw IS NULL THEN 'MISSING_ORDER_TIMESTAMP'
   WHEN o.order_status IS NULL THEN 'MISSING_ORDER-STATUS'
   WHEN O.source_system IS NULL THEN 'MISSING_SOURCE_SYSTEM'

   WHEN o.quantity IS NULL THEN 'INVALID_QUANTITY'
   WHEN o.unit_price IS NULL THEN 'INVALID_UNIT_PRICE'
   WHEN O.order_ts IS NULL THEN 'INVALID_ORDER_TS'

   WHEN o.quantity <= 0 THEN 'NON_POSITIVE_QUANTITY'
   WHEN o.unit_price < 0 THEN 'NEGATIVE_UNIT_PRICE'
   WHEN o.order_status NOT IN ('CREATED','SHIPPED','DELIVERED','CANCELLED') THEN 'INVALID_ORDER_STATUS'

   WHEN c.customer_id IS NULL THEN 'INVALID_CUSTOMER_REF'
   WHEN p.product_id IS NULL THEN 'INVALID_PRODUCT_REF'
   ELSE NULL
  END AS reject_reason
 FROM deduplicate_orders o
 LEFT JOIN customers_ref c ON o.customer_id = c.customer_id
 LEFT JOIN products_ref p ON o.product_id = p.product_id
)
SELECT 
 COALESCE(reject_reason,'VALID') AS verdict,
 COUNT(*) AS row_count
 FROM validated_orders
 GROUP BY verdict
 ORDER BY row_count DESC;


