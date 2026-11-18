CREATE TABLE IF NOT EXISTS
`mahesh2726.ecommerce01_staging.orders_stg`
(
    order_id STRING,
    customer_id STRING,
    product_id STRING,
    quantity STRING,
    unit_price STRING,
    order_ts STRING,
    order_status STRING,
    source_system STRING
);