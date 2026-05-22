CREATE OR REPLACE TABLE `mktg-analysis-project.marketing_data.fact_monthly_performance` AS
WITH raw_with_logic AS (
  SELECT
    raw.Year AS year,
    raw.`Month Number` AS month,
    raw.Region AS region,
    COALESCE(raw.`Customer Number`, CONCAT('GUEST_',raw.`Invoice Number`)) AS customer_id,
    raw.`Invoice Number` AS invoice_number,
    raw.Sell_Out_Amt AS revenue,
    dim.registration_date,
    CASE
      WHEN raw.`Promotion Name` IN ('10% new member', 'Birthday discount program') THEN 'Target Promotion'
      WHEN raw.`Promotion Name` IS NOT NULL THEN 'Other Promotion'
      ELSE 'No Promotion'
    END AS promo_category
  FROM `mktg-analysis-project.marketing_data.sales_data` AS raw
  LEFT JOIN `mktg-analysis-project.marketing_data.dim_customer_segment`AS dim
  ON COALESCE(raw.`Customer Number`,CONCAT('GUEST_',raw.`Invoice Number`)) = dim.customer_id
),

dynamic_table AS (
  SELECT
    *,
    CASE 
      WHEN registration_date IS NULL THEN 'Non-member'
      WHEN EXTRACT(YEAR FROM registration_date) = year
        AND EXTRACT(MONTH FROM registration_date) = month THEN 'New member'
      WHEN registration_date < DATE(year,month,1) THEN 'Old member'
      ELSE 'Other'
    END AS dynamic_customer_type
  FROM raw_with_logic 
)

SELECT
  year, month, region, promo_category, dynamic_customer_type,
  SUM(revenue) AS revenue,
  COUNT(DISTINCT invoice_number) AS orders
FROM dynamic_table
GROUP BY 1,2,3,4,5;
