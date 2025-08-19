create table blinkit.order_fact as
(select  distinct o.order_id,o.order_date,o.customer_id,o.delivery_status,
o.order_total,o.payment_method,o.delivery_partner_id,o.store_id,
o2.product_id,o2.quantity,o2.unit_price,p.category,p.product_name,p.margin_percentage,
extract(epoch FROM (d.actual_time - d.promised_time)) / 60 AS delivery_time,
d.distance_km,d.reasons_if_delayed,
f.rating,f.feedback_category,f.sentiment,c.customer_name,c.customer_segment,c.area
from blinkit.order o
left join blinkit.order_items o2 on o2.order_id=o.order_id 
left join blinkit.product p on p.product_id=o2.product_id
left join blinkit.delivery d on d.order_id = o.order_id 
left join blinkit.feedback f on f.order_id = o.order_id 
left join blinkit.customer c on c.customer_id=o.customer_id
);



-- 1. total sales by day
select order_date, 
       sum(order_total) as daily_sales
from blinkit.order_fact
group by order_date
order by order_date;

-- 2. top 10 selling products by revenue
select product_name, 
       category,
       sum(quantity * unit_price) as total_revenue
from blinkit.order_fact
group by product_name, category
order by total_revenue desc
limit 10;

-- 3. average delivery time and delays
select delivery_status, 
       avg(delivery_time) as avg_delivery_minutes,
       sum(case when reasons_if_delayed is not null then 1 else 0 end) as delayed_orders
from blinkit.order_fact
group by delivery_status;

-- 4. customer segment performance
select customer_segment, 
       count(distinct customer_id) as total_customers,
       sum(order_total) as total_sales,
       avg(f.rating) as avg_rating
from blinkit.order_fact f
group by customer_segment
order by total_sales desc;

-- 5. store level performance
select store_id, 
       sum(order_total) as total_sales,
       avg(delivery_time) as avg_delivery_minutes,
       count(distinct order_id) as total_orders
from blinkit.order_fact
group by store_id
order by total_sales desc;

-- 6. delivery partner efficiency
select delivery_partner_id, 
       avg(delivery_time) as avg_delivery_minutes,
       sum(case when delivery_status = 'delivered' then 1 else 0 end) as successful_deliveries,
       sum(case when delivery_status != 'delivered' then 1 else 0 end) as failed_deliveries
from blinkit.order_fact
group by delivery_partner_id
order by avg_delivery_minutes;

-- 7. sentiment analysis from customer feedback
select sentiment, 
       count(*) as total_reviews,
       avg(rating) as avg_rating
from blinkit.order_fact
where feedback_category is not null
group by sentiment
order by total_reviews desc;

-- 8. margin contribution by category
select category, 
       sum(quantity * unit_price * margin_percentage / 100) as total_margin
from blinkit.order_fact
group by category
order by total_margin desc;
