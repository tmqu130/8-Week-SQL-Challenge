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
