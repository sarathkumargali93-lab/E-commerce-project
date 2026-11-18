CREATE OR REPLACE VIEW
`mahesh2726.ecommerce01_gold.v_total_sales`

AS

SELECT
    SUM(order_amount) AS total_sales

FROM `mahesh2726.ecommerce01_history.orders_history`

WHERE order_status != 'CANCELLED';