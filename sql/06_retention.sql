WITH t AS (
  SELECT
    COALESCE(`Customer Number`, CONCAT('GUEST_',`Invoice Number`)) AS customer_id,
    Date AS order_date,
    Sell_Out_Amt AS revenue,
    `Promotion Name` AS promotion_name,
  FROM `mktg-analysis-project.marketing_data.sales_data` 
  WHERE Sell_Out_Amt > 0
),

customers_22 AS (
  SELECT 
    customer_id,
    MAX(CASE WHEN promotion_name = 'Birthday discount program' THEN 1 ELSE 0 END) AS used_birthday_22,
  FROM t
  WHERE order_date BETWEEN '2022-12-01' AND '2022-12-31'
  GROUP BY customer_id
),

customers_23 AS (
  SELECT 
  customer_id,
  MAX(CASE WHEN promotion_name = 'Birthday discount program' THEN 1 ELSE 0 END) AS used_birthday_23
  FROM t 
  WHERE order_date BETWEEN '2023-12-01' AND '2023-12-31'
  GROUP BY customer_id
)

SELECT
  COUNT(DISTINCT a.customer_id) AS total_customers_22,
  COUNT(DISTINCT b.customer_id) AS total_retained_customers,

  SUM(CASE WHEN a.used_birthday_22 =1 AND b.used_birthday_23 = 1 THEN 1 ELSE 0 END) AS loyal_birthday_users,
  SUM(CASE WHEN a.used_birthday_22 =1 AND (b.used_birthday_23 = 0 OR b.used_birthday_23 IS NULL) THEN 1 ELSE 0 END) AS non_reuse_birthday_users,

FROM customers_22 a
LEFT JOIN customers_23 b ON a.customer_id = b.customer_id; 