 --A. PIZZA METRICS

--1. How many pizzas were ordered?

select count(*) as pizza_ordered
from pizza_runner.customer_orders;

--2. How many unique customer orders were made?

select count (distinct order_id) as order_count
from pizza_runner.customer_orders;

--3. How many successful orders were delivered by each runner?

select 
    runner_id, 
    count(*) as successful_order
from pizza_runner.runner_orders
where cancellation = 'No'
group by runner_id;

--4. How many of each type of pizza was delivered?

alter table pizza_runner.pizza_names
alter column pizza_name varchar(50);

select 
    PN.pizza_id, 
    pizza_name, 
    count(*) as delivered_count
from pizza_runner.customer_orders as CO
left join pizza_runner.pizza_names as PN 
    on CO.pizza_id = PN.pizza_id
join pizza_runner.runner_orders as RO
    on CO.order_id = RO.order_id
where cancellation = 'No'
group by PN.pizza_id, pizza_name;

--5. How many Vegetarian and Meatlovers were ordered by each customer?

select 
    customer_id, 
    pizza_name, 
    count(*) as orders_count
from pizza_runner.customer_orders as CO
left join pizza_runner.pizza_names as PN 
    on CO.pizza_id = PN.pizza_id
group by 
    customer_id, 
    pizza_name
order by customer_id;

--6. What was the maximum number of pizzas delivered in a single order?

with CTE AS
    (select 
        RO.order_id, 
        count(*) as pizza_count
    from pizza_runner.customer_orders as CO
    join pizza_runner.runner_orders as RO 
        on CO.order_id = RO.order_id
    where cancellation = 'No'  
    group by RO.order_id)
select  
    order_id, 
    pizza_count as max_pizza_count
from CTE
where pizza_count = (select max(pizza_count) from CTE);

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select 
    customer_id, 
    count(case when exclusions = '0' and extras = '0' then 1 end) as unchanged,
    count(case when exclusions <> '0' or extras <> '0' then 1 end) as changed
from pizza_runner.customer_orders as CO  
join pizza_runner.runner_orders as RO 
    on CO.order_id = RO.order_id
where cancellation = 'No'
group by customer_id;

--8. How many pizzas were delivered that had both exclusions and extras?

select count(case when exclusions <> '0' and extras <> '0' then 1 end) as both_exclude_and_extra
from pizza_runner.customer_orders as CO  
join pizza_runner.runner_orders as RO 
    on CO.order_id = RO.order_id
where cancellation = 'No';

--9. What was the total volume of pizzas ordered for each hour of the day?

select 
    datepart(hour, order_date) as order_hour, 
    count(*) as pizza_order 
from pizza_runner.customer_orders
group by datepart(hour, order_date);

--10. What was the volume of orders for each day of the week?

select 
    datename (dw, order_date) as day_of_week, 
    count(distinct order_id) as pizza_order
from pizza_runner.customer_orders
group by 
    datename (dw, order_date), 
    datepart (dw, order_date)
order by 
    case   
        when datepart (dw, order_date) = 1 then 7
        else datepart (dw, order_date) - 1
    end;
