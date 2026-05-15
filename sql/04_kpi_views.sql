--Delivery Delay Impact
create or replace view analytics.v_delivery_delay_impact as
SELECT
   delivered_late_flag,
   AVG(payment_value) AS avg_revenue,
   AVG(delivery_days) AS avg_delivery_time
FROM analytics.fact_orders
GROUP BY delivered_late_flag;


--Customer Lifetime Value
create or replace view analytics.v_customer_lifetime_value as
select
	customer_unique_id,
	count(distinct order_id) as total_orders,
	sum(payment_value) as lifetime_revenue,
	avg(payment_value) as avg_order_value
from analytics.fact_orders
group by customer_unique_id;

--Repeat Purchase Rate
create or replace view analytics.v_repeat_purhase_rate as
with customer_orders as (
	select
		customer_unique_id,
		count(order_id) as order_count
	from analytics.fact_orders
	group by customer_unique_id
)
select
	sum(case when order_count>1 then 1 else 0 end)::float
	/ count(*) as repeat_rate
from customer_orders;

--Average order value
create or replace view analytics.v_average_order_value as
select 
	order_month,
	sum(payment_value) / count(distinct order_id) as aov
from analytics.fact_orders
group by order_month
order by order_month asc;

--Unique customer count per month
create or replace view analytics.v_unique_customer_count_per_month as
select
	order_month,
	count(distinct customer_unique_id) as active_customers
from analytics.fact_orders
group by order_month
order by order_month asc;

--Monthly Revenue with growth rate
create or replace view analytics.v_monthly_revenue_rate as
with monthly as (
	select 
		order_month,
		to_char(order_month,'Month') as month_name,
		sum(payment_value) as revenue
		from analytics.fact_orders
		group by order_month
)
select
	order_month,
	month_name,
	revenue,
	lag(revenue) over (order by order_month asc) as prev_month_revenue,
	(revenue - lag(revenue) over (order by order_month)) / nullif(lag(revenue) over (order by order_month),0) as growth_rate
from monthly;

