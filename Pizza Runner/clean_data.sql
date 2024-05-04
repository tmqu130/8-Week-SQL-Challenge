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
