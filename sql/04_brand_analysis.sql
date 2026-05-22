CREATE OR REPLACE TABLE `mktg-analysis-project.marketing_data.brand_analysis` AS

WITH t AS (
  SELECT
    Year AS year, 
    `Month Number` AS month,
    Brand AS brand,
    SAFE.PARSE_DATE('%m/%d/%Y', `Created date`) AS registration_date,
    Sell_Out_Amt AS revenue,
    `Invoice Number` AS order_id,
    Sell_Out_Qty AS quantity,
FROM `mktg-analysis-project.marketing_data.sales_data`
), 

classified AS (
  SELECT
    year, brand,
     CASE 
      WHEN registration_date IS NULL THEN 'Non-member'
      WHEN EXTRACT(YEAR FROM registration_date) = year
        AND EXTRACT(MONTH FROM registration_date) = month THEN 'New member'
      WHEN registration_date < DATE(year,month,1) THEN 'Old member'
      ELSE 'Other'
    END AS dynamic_customer_type,
    order_id,
    revenue,
    quantity
  FROM t
)

SELECT
  year, brand, dynamic_customer_type,
  SUM(revenue) AS total_revenue, 
  COUNT(DISTINCT order_id) AS total_orders,
  SUM (quantity) AS total_units
FROM classified
GROUP BY year, brand, dynamic_customer_type;