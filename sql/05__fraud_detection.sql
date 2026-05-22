CREATE OR REPLACE VIEW `mktg-analysis-project.marketing_data.fraud_detection` AS 
WITH invoice_level AS (
   SELECT
    order_date,
    invoice_number,
    customer_id,
    promotion_name,
    dynamic_customer_type,

    SUM(revenue) AS revenue

  FROM `mktg-analysis-project.marketing_data.fact_transaction_details`

  WHERE
    revenue > 0
    AND EXTRACT(YEAR FROM order_date) = 2023
    AND EXTRACT(MONTH FROM order_date) = 12

  GROUP BY
    order_date,
    invoice_number,
    customer_id,
    promotion_name,
    dynamic_customer_type
),

check_logic AS (
  SELECT
    i.order_date,
    i.invoice_number,
    i.customer_id,
    i.promotion_name,
    i.revenue,
    i.dynamic_customer_type,
    d.is_member,
    d.registration_date,
    DATE_DIFF(
      i.order_date,
      d.registration_date,
      DAY
    ) AS days_since_registration,

    COUNT(DISTINCT i.invoice_number) OVER(
      PARTITION BY i.customer_id, i.promotion_name
    ) AS usage_count
  FROM invoice_level i
  LEFT JOIN `mktg-analysis-project.marketing_data.dim_customer_segment` d
    ON i.customer_id = d.customer_id
)

SELECT
  * EXCEPT(usage_count),
  CASE
    WHEN dynamic_customer_type = 'Non-member'
      AND promotion_name = '10% new member'
    THEN 'Non-member Welcome Voucher Abuse'

     WHEN dynamic_customer_type = 'Non-member'
      AND promotion_name = 'Birthday discount program'
    THEN 'Non-member Birthday Voucher Abuse'

    WHEN promotion_name = '10% new member'
      AND days_since_registration > 15
    THEN 'Policy Violation: Late Welcome code'

    WHEN days_since_registration < 0
    THEN 'Used before registration'

    WHEN promotion_name = '10% new member'
      AND usage_count > 1
    THEN 'Policy Violation: Multiple Usage'

    ELSE 'Review Required'
  END AS fraud_reason
FROM check_logic
WHERE (dynamic_customer_type = 'Non-member' AND promotion_name IN ('10% new member', 'Birthday discount program'))
  OR (promotion_name = '10% new member' AND usage_count > 1)
  OR (promotion_name = '10% new member' AND days_since_registration > 15)
  OR (days_since_registration < 0)