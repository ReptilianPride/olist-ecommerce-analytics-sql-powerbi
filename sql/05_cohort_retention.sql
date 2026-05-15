-- this is happening in analytics schema

CREATE OR REPLACE VIEW analytics.v_cohort_retention AS
WITH customer_activity AS (
    SELECT DISTINCT
        customer_unique_id,
        cohort_month,
        order_month
    FROM analytics.fact_orders
),
cohort_periods AS (
    SELECT
        customer_unique_id,
        cohort_month,
        order_month,
        (
            EXTRACT(YEAR FROM AGE(order_month, cohort_month)) * 12
            + EXTRACT(MONTH FROM AGE(order_month, cohort_month))
        )::int AS period_number
    FROM customer_activity
),
cohort_counts AS (
    SELECT
        cohort_month,
        period_number,
        COUNT(DISTINCT customer_unique_id) AS customers_retained
    FROM cohort_periods
    GROUP BY cohort_month, period_number
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_activity
    WHERE order_month = cohort_month
    GROUP BY cohort_month
)
SELECT
    c.cohort_month,
    c.period_number,
    c.customers_retained,
    s.cohort_size,
    ROUND(
        c.customers_retained::numeric / s.cohort_size,
        4
    ) AS retention_rate
FROM cohort_counts c
JOIN cohort_sizes s
    ON c.cohort_month = s.cohort_month
ORDER BY c.cohort_month, c.period_number;