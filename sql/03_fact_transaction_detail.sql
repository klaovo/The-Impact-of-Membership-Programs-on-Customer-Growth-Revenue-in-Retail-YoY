CREATE OR REPLACE TABLE `mktg-analysis-project.marketing_data.fact_transaction_details` AS
SELECT
  raw.Date AS order_date,
  raw.`Invoice Number` AS invoice_number,
  COALESCE(raw.`Customer Number`,CONCAT('GUEST_',raw.`Invoice Number`)) AS customer_id,
  raw.`Promotion Name` AS promotion_name,
  raw.Sell_Out_Amt AS revenue,
  
  CASE
    WHEN dim.registration_date IS NULL THEN 'Non-member'
    WHEN EXTRACT(YEAR FROM dim.registration_date) = raw.Year
      AND EXTRACT(MONTH FROM dim.registration_date) = raw.`Month Number` THEN 'New member'
    WHEN dim.registration_date < DATE(raw.Year,raw.`Month Number`,1) THEN 'Old member'
    ELSE 'Other'
  END AS dynamic_customer_type
FROM `mktg-analysis-project.marketing_data.sales_data` AS raw
LEFT JOIN `mktg-analysis-project.marketing_data.dim_customer_segment` AS dim
  ON COALESCE(raw.`Customer Number`,CONCAT('GUEST_',raw.`Invoice Number`)) = dim.customer_id
WHERE raw.`Promotion Name` IN ('10% new member', 'Birthday discount program');