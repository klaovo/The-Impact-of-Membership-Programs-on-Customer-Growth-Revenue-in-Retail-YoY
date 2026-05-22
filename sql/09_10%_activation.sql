CREATE OR REPLACE VIEW `mktg-analysis-project.marketing_data.activation_dec_2023` AS

WITH t AS (
  SELECT
    COALESCE(raw.`Customer Number`, CONCAT('GUEST_', raw.`Invoice Number`)) AS customer_id,
    PARSE_DATE('%m/%d/%Y', raw.`Created date`) AS registration_date,
    DATE(raw.`Date`) AS order_date,
    raw.`Promotion Name` AS promotion_name
  FROM `mktg-analysis-project.marketing_data.sales_data` raw
),

dec_2023_members AS (
  SELECT DISTINCT
    customer_id,
    registration_date
  FROM t
  WHERE registration_date BETWEEN '2023-12-01' AND '2023-12-31'
),

same_day_usage AS (
  SELECT
    m.customer_id,
    MAX(CASE 
      WHEN b.promotion_name = '10% new member'
       AND b.order_date = m.registration_date
      THEN 1 ELSE 0
    END) AS used_same_day
  FROM dec_2023_members m
  LEFT JOIN t b ON m.customer_id = b.customer_id
  GROUP BY m.customer_id
)

SELECT
  COUNT(*) AS total_new_members_dec_2023,
  SUM(CASE WHEN used_same_day = 1 THEN 1 ELSE 0 END) AS same_day_users,
  SUM(CASE WHEN used_same_day = 0 THEN 1 ELSE 0 END) AS not_used_same_day_users,
FROM same_day_usage;