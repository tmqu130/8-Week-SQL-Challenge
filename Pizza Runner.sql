create schema pizza_runner;
GO

create table pizza_runner.runners (
    runner_id int,
    registration_date date
);

insert into pizza_runner.runners
values 
    (1, '2021-01-01'),
    (2,	'2021-01-03'),
    (3,	'2021-01-08'),
    (4,	'2021-01-15');

create table pizza_runner.customer_orders (
    order_id int,
    customer_id int,
    pizza_id int,
    exclusions varchar(4),
    extras varchar(4),
    order_date datetime
);

insert into pizza_runner.customer_orders
values
    (1, 101, 1, '', '', '2021-01-01 18:05:02'),
    (2,	101, 1, '', '',	'2021-01-01 19:00:52'),
    (3,	102, 1, '', '', '2021-01-02 23:51:23'),
    (3,	102, 2, '', 'NaN', '2021-01-02 23:51:23'),
    (4,	103, 1,	'4', '', '2021-01-04 13:23:46'),
    (4,	103, 1,	'4', '', '2021-01-04 13:23:46'),
    (4,	103, 2,	'4', '', '2021-01-04 13:23:46'),
    (5, 104, 1, null, '1',	'2021-01-08 21:00:29'),
    (6,	101, 2,	null, null, '2021-01-08 21:03:13'),
    (7,	105, 2,	null, '1', '2021-01-08 21:20:29'),
    (8,	102, 1,	null, null,	'2021-01-09 23:54:33'),
    (9,	103, 1,	'4', '1, 5', '2021-01-10 11:22:59'),
    (10, 104, 1, null, null, '2021-01-11 18:34:49'),
    (10, 104, 1, '2, 6', '1, 4', '2021-01-11 18:34:49');

create table pizza_runner.runner_orders (
    order_id int,
    runner_id int,
    pickup_time varchar(19),
    distance varchar(7),
    duration varchar(10),
    cancellation varchar(23)
);

insert into pizza_runner.runner_orders
values
    (1,	1, '2021-01-01 18:15:34', '20km', '32 minutes', ''),	 
    (2,	1,	'2021-01-01 19:10:54', '20km', '27 minutes', ''),	 
    (3,	1, '2021-01-03 00:12:37', '13.4km',	'20 mins', 'NaN'),
    (4,	2, '2021-01-04 13:53:03', '23.4', '40', 'NaN'),
    (5,	3, '2021-01-08 21:10:57', '10', '15', 'NaN'),
    (6,	3, null, null, null, 'Restaurant Cancellation'),
    (7,	2, '2020-01-08 21:30:45', '25km', '25mins', null),
    (8,	2, '2020-01-10 00:15:02', '23.4 km', '15 minute', null),
    (9,	2, null, null, null, 'Customer Cancellation'),
    (10, 1,	'2020-01-11 18:50:20', '10km', '10minutes',	null);

create table pizza_runner.pizza_names (
    pizza_id int,
    pizza_name text
);

insert into pizza_runner.pizza_names
values
    (1, 'Meat Lovers'),
    (2, 'Vegetarian');

create table pizza_runner.pizza_recipes (
    pizza_id int,
    toppings text
);

insert into pizza_runner.pizza_recipes
values
    (1,	'1, 2, 3, 4, 5, 6, 8, 10'),
    (2,	'4, 6, 7, 9, 11, 12');

create table pizza_runner.pizza_toppings (
    topping_id int,
    topping_name text
);

insert into pizza_runner.pizza_toppings
values 
    (1, 'Bacon'),
    (2, 'BBQ Sauce'),
    (3,	'Beef'),
    (4,	'Cheese'),
    (5,	'Chicken'),
    (6,	'Mushrooms'),
    (7,	'Onions'),
    (8,	'Pepperoni'),
    (9,	'Peppers'),
    (10, 'Salami'),
    (11, 'Tomatoes'),
    (12, 'Tomato Sauce');

--Before you start writing your SQL queries however - you might want to investigate the data, you may want to do something with some of those null values and data types in the customer_orders and runner_orders tables!

select * from pizza_runner.customer_orders;

update pizza_runner.customer_orders
set exclusions = '0'
where exclusions = '' or exclusions is null;

update pizza_runner.customer_orders
set extras = '0'
where extras in ('', 'NaN') or extras is null;

select * from pizza_runner.runner_orders;

    update pizza_runner.runner_orders
    set cancellation = 'No'
    where cancellation in ('', 'NaN') or cancellation is null;

    with X as
        (select order_id,
        (SELECT value FROM STRING_SPLIT(cancellation, ' ') WHERE value <> '' ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY) AS first_value
        FROM pizza_runner.runner_orders)
    update pizza_runner.runner_orders
    set cancellation = first_value
    from X
    join pizza_runner.runner_orders as RO 
        on X.order_id = RO.order_id;

    update pizza_runner.runner_orders
    set duration = case 
        when duration is null then ''
        when duration like '%minutes' then trim ('minutes' from duration)
        when duration like '%mins%' then trim ('mins' from duration)
        when duration like '%minute%' then trim ('minute' from duration)
        else duration
    end;

    update pizza_runner.runner_orders
    set distance = case 
        when distance is null then ''
        when distance like '%km' then trim ('km' from distance)
        else distance
    end;

    update pizza_runner.runner_orders
    set pickup_time = ''
    where pickup_time is null;

    alter table pizza_runner.runner_orders
    alter column pickup_time datetime null;

    alter table pizza_runner.runner_orders
    alter column distance float null;

    alter table pizza_runner.runner_orders
    alter column duration int null;
    
--A. PIZZA METRICS

--1. How many pizzas were ordered?

select count(*) as pizza_ordered
from pizza_runner.customer_orders;

--2. How many unique customer orders were made?

select count (distinct order_id) as order_number
from pizza_runner.customer_orders;

--3. How many successful orders were delivered by each runner?

select runner_id, count(*) as successful_order
from pizza_runner.runner_orders
where cancellation = 'No'
group by runner_id;

--4. How many of each type of pizza was delivered?

alter table pizza_runner.pizza_names
alter column pizza_name varchar(50);

select PN.pizza_id, pizza_name, count(*) as order_number
from pizza_runner.customer_orders as CO
left join pizza_runner.pizza_names as PN 
    on CO.pizza_id = PN.pizza_id
join pizza_runner.runner_orders as RO
    on CO.order_id = RO.order_id
where cancellation = 'No'
group by PN.pizza_id, pizza_name;

--5. How many Vegetarian and Meatlovers were ordered by each customer?

select customer_id, pizza_name, count(*) as order_number
from pizza_runner.customer_orders as CO
left join pizza_runner.pizza_names as PN 
    on CO.pizza_id = PN.pizza_id
group by customer_id, pizza_name
order by customer_id;

--6. What was the maximum number of pizzas delivered in a single order?

with CTE AS
    (select order_id, count(*) as pizza_number
    from pizza_runner.customer_orders
    group by order_id)
select CTE.order_id, pizza_number as max_pizza_number
from CTE
join pizza_runner.runner_orders as RO 
    on CTE.order_id = RO.order_id
where cancellation = 'No' and
    pizza_number = (select max(pizza_number) from CTE);

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select customer_id, 
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

select datepart(hour, order_date) as order_hour, count(*) as pizza_order 
from pizza_runner.customer_orders
group by datepart(hour, order_date);

--10. What was the volume of orders for each day of the week?

select datename (dw, order_date) as day_of_week, count(distinct order_id) as pizza_order
from pizza_runner.customer_orders
group by datename (dw, order_date), datepart (dw, order_date)
order by case   
    when datepart (dw, order_date) = 1 then 7
    else datepart (dw, order_date) - 1
    end;

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

--C. Ingredient Optimisation

--1. What are the standard ingredients for each pizza?

alter table pizza_runner.pizza_recipes
alter column toppings varchar(50);

alter table pizza_runner.pizza_toppings
alter column topping_name varchar(50);

with CTE as
    (select PR.pizza_id, pizza_name, trim(value) AS topping
    from pizza_runner.pizza_recipes as PR 
    join pizza_runner.pizza_names as PN
        on PR.pizza_id = PN.pizza_id
    cross apply string_split (toppings, ','))
select pizza_id, pizza_name, string_agg (topping_name, ', ') as pizza_ingredients
from CTE
join pizza_runner.pizza_toppings as PT 
    on CTE.topping = PT.topping_id
group by pizza_id, pizza_name;

--2. What was the most commonly added extra?

with CTE1 as 
    (select trim(value) as extra_ingredient
    from pizza_runner.customer_orders
    cross apply string_split(extras, ',')
    where extras <> '0'),
CTE2 as
    (select extra_ingredient, topping_name, count(*) as added_extra
    from CTE1
    join pizza_runner.pizza_toppings as PT 
        on extra_ingredient = PT.topping_id
    group by extra_ingredient, topping_name)
select extra_ingredient as added_most_topping, topping_name, added_extra as added_times
from CTE2 
where added_extra = (select max(added_extra) from CTE2);

--3. What was the most common exclusion?

with CTE1 as 
    (select trim(value) as exclude_ingredient
    from pizza_runner.customer_orders
    cross apply string_split(exclusions, ',')
    where exclusions <> '0'),
CTE2 as
    (select exclude_ingredient, topping_name, count(*) as exclusion_times
    from CTE1
    join pizza_runner.pizza_toppings as PT 
        on exclude_ingredient = PT.topping_id
    group by exclude_ingredient, topping_name)
select exclude_ingredient as excluded_most_topping, topping_name, exclusion_times as excluded_times
from CTE2 
where exclusion_times = (select max(exclusion_times) from CTE2);

--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
    --Meat Lovers
    --Meat Lovers - Exclude Beef
    --Meat Lovers - Extra Bacon
    --Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

with CTE as 
    (select row_number () over (order by order_id, pizza_id) as order_line, CO.*
    from pizza_runner.customer_orders as CO),
CTE1A as
    (select CTE.*, trim(exclude.value) as exclude
    from CTE
    cross apply string_split (exclusions, ',') as exclude),
CTE1B as
    (select CTE.*, trim(extra.value) as extra
    from CTE
    cross apply string_split (extras, ',') as extra),
CTE2A as
    (select order_line, order_id, pizza_id, exclusions, extras, PT.topping_name as exclude
    from CTE1A
    left join pizza_runner.pizza_toppings as PT
        on CTE1A.exclude = PT.topping_id),
CTE2B as
    (select order_line, order_id, pizza_id, exclusions, extras, PT.topping_name as extra
    from CTE1B
    left join pizza_runner.pizza_toppings as PT
        on CTE1B.extra = PT.topping_id),
CTE3A as
    (select order_line, concat(exclusions, extras) as require, string_agg(exclude, ', ') as exclusions
    from CTE2A
    join pizza_runner.pizza_names as PN 
        on CTE2A.pizza_id = PN.pizza_id
    group by order_line, concat(exclusions, extras)),
CTE3B as
    (select order_line, concat(exclusions, extras) as require, string_agg(extra, ', ') as extras
    from CTE2B
    join pizza_runner.pizza_names as PN 
        on CTE2B.pizza_id = PN.pizza_id
    group by order_line, concat(exclusions, extras))
select order_id, customer_id, CTE.pizza_id, case 
        when CTE3A.exclusions is null and CTE3B.extras is null then pizza_name
        when CTE3A.exclusions is not null and CTE3B.extras is null then concat(pizza_name, ' - Exclude ', CTE3A.exclusions)
        when CTE3A.exclusions is null and CTE3B.extras is not null then concat(pizza_name, ' - Extra ', CTE3B.extras)
        when CTE3A.exclusions is not null and CTE3B.extras is not null then concat(pizza_name, ' - Exclude ', CTE3A.exclusions, ' - Extra ', CTE3B.extras)
    end as order_item
    , CTE.exclusions, CTE.extras, order_date
from CTE3A
join CTE3B 
    on CTE3A.order_line = CTE3B.order_line and CTE3A.require = CTE3B.require
join CTE
    on CTE3A.order_line = CTE.order_line
join pizza_runner.pizza_names as PN 
    on CTE.pizza_id = PN.pizza_id 
order by CTE3A.order_line;

--5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
    --For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

with CTE as 
    (select row_number () over (order by order_id, pizza_id) as order_line, CO.*
    from pizza_runner.customer_orders as CO),
CTE1A as
    (select pizza_id, trim(value) as ingredient
    from pizza_runner.pizza_recipes
    cross apply string_split(toppings, ',') as ingredient),
CTE1B as
    (select pizza_id, topping_id, topping_name as ingredient
    from CTE1A
    join pizza_runner.pizza_toppings as PT 
        on CTE1A.ingredient = PT.topping_id),
CTE2 as
    (select order_line, order_id, customer_id, CTE.pizza_id, pizza_name, (case 
            when charindex(cast(topping_id as varchar(max)), extras) > 0 then concat ('2x', ingredient)
            when charindex(cast(topping_id as varchar(max)), exclusions) > 0 then null
            else ingredient
        end) 
        as ingredient
        , CTE.order_date 
    from CTE
    join pizza_runner.pizza_names as PN 
        on CTE.pizza_id = PN.pizza_id 
    join CTE1B
        on CTE.pizza_id = CTE1B.pizza_id)
select 
    order_line, 
    order_id, 
    customer_id, 
    pizza_id, 
    concat(pizza_name, ': ', string_agg(ingredient, ', ' ) within group (order by ingredient asc)) as ingredient_list 
from CTE2
group by order_line, order_id, customer_id, pizza_id, pizza_name
order by order_line;

--6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

with CTE1 as
    (select pizza_id, trim(value) as ingredient_id
    from pizza_runner.pizza_recipes
    cross apply string_split(toppings, ',')),
CTE2 as
    (select 
        CO.order_id,
        PT.topping_name as ingredient,
        case
            when charindex(cast(PT.topping_id as varchar), CO.extras) > 0 then 2
            when charindex(cast(PT.topping_id as varchar), CO.exclusions) > 0 then 0
            else 1
        end as times_used
    from pizza_runner.customer_orders as CO
    join CTE1
        on CO.pizza_id = CTE1.pizza_id
    join pizza_runner.pizza_toppings as PT
        on topping_id = ingredient_id)
select ingredient, sum(times_used) as times_used 
from 
  CTE2
group by 
  ingredient
order by
  times_used desc;

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

--E. Bonus Questions

--If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
--Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

insert into pizza_runner.pizza_names
values (3, ' Supreme')

insert into pizza_runner.pizza_recipes
values (
    3, 
    (select string_agg (topping_id, ', ') as toppings
    from pizza_runner.pizza_toppings)
);
