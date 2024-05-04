--D. Pricing and Ratings

--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes  
    --how much money has Pizza Runner made so far if there are no delivery fees?

with CTE as
    (select case 
            when pizza_name = 'Meat Lovers' then 12
            when pizza_name = 'Vegetarian' then 10
        end as Amount
    from pizza_runner.customer_orders as CO
    join pizza_runner.pizza_names as PN
        on CO.pizza_id = PN.pizza_id
    join pizza_runner.runner_orders as RO  
        on CO.order_id = RO.order_id
    where cancellation = 'No')
select sum(Amount) as Revenue
from CTE;

--2. What if there was an additional $1 charge for any pizza extras?
    --Add cheese is $1 extra

with CTE1 as 
    (select row_number() over (order by order_id, pizza_id) as order_line, *
    from pizza_runner.customer_orders),
CTE2 as  
    (select order_line, trim(value) as extra_ingredient
    from CTE1
    cross apply string_split(extras, ',')),
CTE3 as 
    (select order_line, count(case when extra_ingredient <> 0 then 1 end) as ingredient_count
    from CTE2
    group by order_line),
CTE4 as
    (select CTE1.*, case
            when pizza_name = 'Meat Lovers' then (12 + ingredient_count*1)
            when pizza_name = 'Vegetarian' then (10 + ingredient_count*1)
        end as Amount
    from CTE1 
    join CTE3
        on CTE1.order_line = CTE3.order_line
    join pizza_runner.pizza_names as PN
        on CTE1.pizza_id = PN.pizza_id
    join pizza_runner.runner_orders as RO  
        on CTE1.order_id = RO.order_id
    where cancellation = 'No')
select sum(Amount) as Revenue
from CTE4;

--3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
    --how would you design an additional table for this new dataset
    --generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

create table pizza_runner.ratings (
    order_id int,
    rating int
)

insert into pizza_runner.ratings
values 
  (1,3),
  (2,5),
  (3,3),
  (4,1),
  (5,5),
  (7,3),
  (8,4),
  (10,3);

--4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
    --customer_id
    --order_id
    --runner_id
    --rating
    --order_time
    --pickup_time
    --Time between order and pickup
    --Delivery duration
    --Average speed
    --Total number of pizzas

select 
    customer_id, 
    CO.order_id, 
    runner_id, 
    rating, 
    order_date as order_time, 
    pickup_time, 
    datediff(minute, order_date, pickup_time) as arriving_time, 
    duration, 
    round((distance/(cast(duration as float)/60)), 1)  as avg_speed,
    count(*) as pizza_number
from pizza_runner.customer_orders as CO 
join pizza_runner.runner_orders as RO   
    on CO.order_id = RO.order_id
join pizza_runner.ratings as R 
    on CO.order_id = R.order_id
where cancellation = 'No'
group by customer_id, 
    CO.order_id, 
    runner_id, 
    rating, 
    order_date, 
    pickup_time, 
    datediff(minute, order_date, pickup_time), 
    duration, 
    round((distance/(cast(duration as float)/60)), 1)
order by order_id;

--5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
    --how much money does Pizza Runner have left over after these deliveries?

with CTE1A as
    (select case 
            when pizza_name = 'Meat Lovers' then 12
            when pizza_name = 'Vegetarian' then 10
        end as amount
    from pizza_runner.customer_orders as CO
    join pizza_runner.pizza_names as PN
        on CO.pizza_id = PN.pizza_id
    join pizza_runner.runner_orders as RO   
        on CO.order_id = RO.order_id
    where cancellation = 'No'),
CTE1B as 
    (select 0.3*distance as runner_cost
    from pizza_runner.runner_orders),
CTE2A as    
    (select sum(amount) as revenue
    from CTE1A),
CTE2B as 
    (select sum(runner_cost) as runner_cost
    from CTE1B)
select (revenue - runner_cost) as left_over
from CTE2A, CTE2B;
