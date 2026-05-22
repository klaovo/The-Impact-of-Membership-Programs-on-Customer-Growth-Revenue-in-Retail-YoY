CREATE OR REPLACE TABLE `mktg-analysis-project.marketing_data.dim_customer_segment` AS
WITH all_unique_ids AS (
  SELECT 
  COALESCE(`Customer Number`, CONCAT('GUEST_',`Invoice Number`)) AS customer_id,
  `Customer Number` AS original_member_id,
  SAFE.PARSE_DATE('%m/%d/%Y', `Created date`) AS registration_date,
  Date AS order_date
  FROM `mktg-analysis-project.marketing_data.sales_data`
),

first_purchase AS (
  SELECT 
  customer_id,
  MIN (order_date) AS first_order_date,
  MIN (registration_date) AS registration_date,
  MAX(original_member_id) AS original_member_id
  FROM all_unique_ids
  GROUP BY 1
)

SELECT
  customer_id,
  registration_date,
  first_order_date,
  CASE
    WHEN original_member_id IS NULL THEN FALSE
    ELSE TRUE
  END AS is_member
FROM first_purchase;