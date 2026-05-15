-- Create the below in the analytics schema
-- Contains an aggregated table from the imported data with usable information

DROP TABLE IF EXISTS analytics.fact_orders;

CREATE TABLE analytics.fact_orders AS
WITH order_totals AS (
    SELECT
        oi.order_id,
        SUM(oi.price) AS item_revenue,
        SUM(oi.freight_value) AS freight_revenue
    FROM raw.olist_order_items_dataset oi
    GROUP BY oi.order_id
),
payment_totals AS (
    SELECT
        op.order_id,
        SUM(op.payment_value) AS payment_value
    FROM raw.olist_order_payments_dataset op
    GROUP BY op.order_id
),
product_categories AS (
    SELECT
        oi.order_id,
        COUNT(DISTINCT p.product_category_name) AS distinct_categories,
        MIN(p.product_category_name) AS primary_category
    FROM raw.olist_order_items_dataset oi
    LEFT JOIN raw.olist_products_dataset p
        ON oi.product_id = p.product_id
    GROUP BY oi.order_id
),
customer_first_purchase AS (
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase_date
    FROM raw.olist_orders_dataset o
    JOIN raw.olist_customers_dataset c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
    DATE_TRUNC('quarter', o.order_purchase_timestamp) AS order_quarter,

    cfp.first_purchase_date,
    DATE_TRUNC('month', cfp.first_purchase_date) AS cohort_month,

    ot.item_revenue,
    ot.freight_revenue,
    pt.payment_value,

    pc.primary_category,
    pc.distinct_categories,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN (
            o.order_delivered_customer_date::date
            - o.order_purchase_timestamp::date
        )
        ELSE NULL
    END AS delivery_days,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 1
        ELSE 0
    END AS delivered_late_flag,

    CASE
        WHEN o.order_status = 'delivered' THEN 1
        ELSE 0
    END AS delivered_flag

FROM raw.olist_orders_dataset o
LEFT JOIN raw.olist_customers_dataset c
    ON o.customer_id = c.customer_id
LEFT JOIN order_totals ot
    ON o.order_id = ot.order_id
LEFT JOIN payment_totals pt
    ON o.order_id = pt.order_id
LEFT JOIN product_categories pc
    ON o.order_id = pc.order_id
LEFT JOIN customer_first_purchase cfp
    ON c.customer_unique_id = cfp.customer_unique_id;
