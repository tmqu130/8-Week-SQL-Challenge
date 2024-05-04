--B. Runner and Customer Experience

--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

select (datediff(week, '2021-01-01', registration_date) + 1) as week, count(*) as regis_runner
from pizza_runner.runners
group by datediff(week, '2021-01-01', registration_date);

--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

update pizza_runner.runner_orders
set pickup_time = dateadd (year, 1, pickup_time)
where pickup_time >= '2020-01-01' and pickup_time < '2021-01-01';

with CTE as 
    (select distinct order_id, order_date
    from pizza_runner.customer_orders)
select avg(datediff(minute, order_date, pickup_time)) as avg_arrive_time
from CTE  
join pizza_runner.runner_orders as RO   
    on CTE.order_id = RO.order_id
where cancellation = 'No'; 

--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

with CTE as 
    (select order_id, count(pizza_id) as pizza_number
    from pizza_runner.customer_orders
    group by order_id)
select pizza_number, avg(datediff(minute, order_date, pickup_time)) as avg_arrive_time
from CTE  
join pizza_runner.customer_orders as CO 
    on CTE.order_id = CO.order_id
join pizza_runner.runner_orders as RO   
    on CTE.order_id = RO.order_id
where cancellation = 'No'
group by pizza_number;

--4. What was the average distance travelled for each customer?

select customer_id, round(avg(distance), 1) as avg_customer_distance
from pizza_runner.customer_orders as CO 
join pizza_runner.runner_orders as RO 
    on CO.order_id = RO.order_id
where cancellation = 'No'
group by customer_id;

--5. What was the difference between the longest and shortest delivery times for all orders?

select max(duration) - min(duration) as delivery_time_diff
from pizza_runner.runner_orders
where cancellation = 'No';

--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

select runner_id, order_id, distance, round((cast(duration as float)/60), 1) as duration, round((distance/(cast(duration as float)/60)), 1)  as avg_speed
from pizza_runner.runner_orders
where cancellation = 'No'
order by runner_id, (distance/(cast(duration as float)/60));

--7. What is the successful delivery percentage for each runner?

select runner_id,  
    cast(count(case when cancellation = 'No' then 1 end) as float)/cast(count(*) as float) as successful_rate
from pizza_runner.runner_orders
group by runner_id;
