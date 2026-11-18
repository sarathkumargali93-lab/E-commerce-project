SELECT 'customers_stg' AS table_name, COUNT(*) AS row_count
FROM `mahesh2726.ecommerce01_staging.customers_stg`

UNION ALL

SELECT 'products_stg', COUNT(*)
FROM `mahesh2726.ecommerce01_staging.products_stg`

UNION ALL

SELECT 'orders_stg', COUNT(*)
FROM `mahesh2726.ecommerce01_staging.orders_stg`

UNION ALL

SELECT 'payments_stg', COUNT(*)
FROM `mahesh2726.ecommerce01_staging.payments_stg`;