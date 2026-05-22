CREATE OR REPLACE VIEW `mktg-analysis-project.marketing_data.birthday_user_analysis` AS

WITH birthday_2022 AS (
  SELECT DISTINCT customer_id
  FROM `mktg-analysis-project.marketing_data.fact_transaction_details`
  WHERE promotion_name = 'Birthday discount program'
    AND EXTRACT(YEAR FROM order_date) = 2022
),

birthday_2023 AS (
  SELECT DISTINCT customer_id
  FROM `mktg-analysis-project.marketing_data.fact_transaction_details`
  WHERE promotion_name = 'Birthday discount program'
    AND EXTRACT(YEAR FROM order_date) = 2023
),

customer_group AS (
  SELECT
    b23.customer_id,
    CASE
      WHEN b22.customer_id IS NOT NULL THEN 'Repeat Birthday Users'
      ELSE 'First-time Birthday Users'
    END AS birthday_user_group
  FROM birthday_2023 b23
  LEFT JOIN birthday_2022 b22
    ON b23.customer_id = b22.customer_id
)

SELECT
  cg.birthday_user_group,
  COUNT(DISTINCT f.customer_id) AS customers,
  SUM(f.revenue) AS revenue,
  SAFE_DIVIDE(
    SUM(f.revenue),
    COUNT(DISTINCT f.invoice_number)
  ) AS AOV
FROM `mktg-analysis-project.marketing_data.fact_transaction_details` f
JOIN customer_group cg
  ON f.customer_id = cg.customer_id
WHERE promotion_name = 'Birthday discount program'
  AND EXTRACT(YEAR FROM order_date) = 2023
  AND revenue > 0
GROUP BY 1