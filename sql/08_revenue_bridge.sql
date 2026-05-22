CREATE OR REPLACE VIEW `mktg-analysis-project.marketing_data.revenue_bridge_dec_2022_2023` AS
WITH t AS (
  SELECT
    COALESCE(`Customer Number`, CONCAT('GUEST_', `Invoice Number`)) AS customer_id,
    Date AS order_date,
    Year AS year,
    `Month Number` AS month,
    Sell_Out_Amt AS revenue,
    SAFE.PARSE_DATE('%m/%d/%Y', `Created date`) AS registration_date,
    CASE
      WHEN `Customer Number` IS NULL THEN 'Non-member'
      WHEN EXTRACT(YEAR FROM SAFE.PARSE_DATE('%m/%d/%Y', `Created date`)) = Year
       AND EXTRACT(MONTH FROM SAFE.PARSE_DATE('%m/%d/%Y', `Created date`)) = `Month Number` THEN 'New member'
      WHEN SAFE.PARSE_DATE('%m/%d/%Y', `Created date`) < DATE(Year,`Month Number`,1) THEN 'Old member'
      ELSE 'Other'
    END AS dynamic_customer_type

  FROM `mktg-analysis-project.marketing_data.sales_data`
),

cust_2022 AS (
  SELECT
    customer_id,
    SUM(revenue) AS revenue_2022
  FROM t
  WHERE year = 2022 AND month = 12
  GROUP BY customer_id
),

cust_2023 AS (
  SELECT
    customer_id,
    SUM(revenue) AS revenue_2023,
    MAX(
      CASE
        WHEN dynamic_customer_type IN ('New member','Non-member')
        THEN 1 ELSE 0
      END
    ) AS is_new_or_non_2023
  FROM t
  WHERE year = 2023 AND month = 12
  GROUP BY customer_id
),

joined AS (
  SELECT
    COALESCE(a.customer_id, b.customer_id) AS customer_id,
    a.revenue_2022,
    b.revenue_2023,
    b.is_new_or_non_2023

  FROM cust_2022 a
  FULL OUTER JOIN cust_2023 b
    ON a.customer_id = b.customer_id
)

SELECT
  SUM(IFNULL(revenue_2022,0)) AS revenue_dec_2022,

  SUM(
    CASE
      WHEN revenue_2022 IS NOT NULL
       AND revenue_2023 IS NULL
      THEN revenue_2022
      ELSE 0
    END
  ) AS revenue_loss,

  SUM(
    CASE
      WHEN revenue_2022 IS NULL
       AND revenue_2023 IS NOT NULL
       AND is_new_or_non_2023 = 1
      THEN revenue_2023
      ELSE 0
    END
  ) AS revenue_gain_from_new_members,

  SUM(
    CASE
      WHEN revenue_2022 IS NOT NULL
       AND revenue_2023 IS NOT NULL
      THEN revenue_2023 - revenue_2022
      ELSE 0
    END
  ) AS revenue_variance_retained_members

FROM joined;