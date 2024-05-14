--C. Ingredient Optimisation

--1. What are the standard ingredients for each pizza?

alter table pizza_runner.pizza_recipes
alter column toppings varchar(50);

alter table pizza_runner.pizza_toppings
alter column topping_name varchar(50);

with CTE as
    (select 
        PR.pizza_id, 
        pizza_name, 
        trim(value) AS topping
    from pizza_runner.pizza_recipes as PR 
    join pizza_runner.pizza_names as PN
        on PR.pizza_id = PN.pizza_id
    cross apply string_split (toppings, ','))
select 
    pizza_id, 
    pizza_name, 
    string_agg (topping_name, ', ') as pizza_ingredients
from CTE
join pizza_runner.pizza_toppings as PT 
    on CTE.topping = PT.topping_id
group by pizza_id, pizza_name
order by pizza_id;

--2. What was the most commonly added extra?

with CTE1 as 
    (select trim(value) as extra_ingredient
    from pizza_runner.customer_orders
    cross apply string_split(extras, ',')
    where extras <> '0'),
CTE2 as
    (select 
        extra_ingredient, 
        topping_name, 
        count(*) as added_extra
    from CTE1
    join pizza_runner.pizza_toppings as PT 
        on extra_ingredient = PT.topping_id
    group by 
        extra_ingredient, 
        topping_name)
select 
    topping_name as added_most_topping, 
    added_extra as added_times
from CTE2 
where added_extra = (select max(added_extra) from CTE2);

--3. What was the most common exclusion?

with CTE1 as 
    (select trim(value) as exclude_ingredient
    from pizza_runner.customer_orders
    cross apply string_split(exclusions, ',')
    where exclusions <> '0'),
CTE2 as
    (select 
        exclude_ingredient, 
        topping_name, 
        count(*) as exclusion_times
    from CTE1
    join pizza_runner.pizza_toppings as PT 
        on exclude_ingredient = PT.topping_id
    group by 
        exclude_ingredient, 
        topping_name)
select 
    topping_name as excluded_most_topping, 
    exclusion_times as excluded_times
from CTE2 
where exclusion_times = (select max(exclusion_times) from CTE2);

--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
    --Meat Lovers
    --Meat Lovers - Exclude Beef
    --Meat Lovers - Extra Bacon
    --Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

with CTE as 
    (select 
        CO.*,
        row_number () over (order by order_id, pizza_id) as order_line
    from pizza_runner.customer_orders as CO),
CTE1A as
    (select 
        CTE.*, 
        trim(exclude.value) as exclude
    from CTE
    cross apply string_split (exclusions, ',') as exclude),
CTE1B as
    (select 
        CTE.*,
        trim(extra.value) as extra
    from CTE
    cross apply string_split (extras, ',') as extra),
CTE2A as 
    (select 
        order_line, 
        concat(exclusions, extras) as require, 
        string_agg(topping_name, ', ') as exclusions
    from CTE1A
    join pizza_runner.pizza_names as PN 
        on CTE1A.pizza_id = PN.pizza_id
    left join pizza_runner.pizza_toppings as PT
        on CTE1A.exclude = PT.topping_id
    group by 
        order_line, 
        concat(exclusions, extras)),
CTE2B as
    (select 
        order_line, 
        concat(exclusions, extras) as require, 
        string_agg(topping_name, ', ') as extras
    from CTE1B
    join pizza_runner.pizza_names as PN 
        on CTE1B.pizza_id = PN.pizza_id
    left join pizza_runner.pizza_toppings as PT
        on CTE1B.extra = PT.topping_id
    group by 
        order_line, 
        concat(exclusions, extras))
select 
    order_id, 
    customer_id, 
    CTE.pizza_id, 
    case 
        when CTE2A.exclusions is null and CTE2B.extras is null then pizza_name
        when CTE2A.exclusions is not null and CTE2B.extras is null then concat(pizza_name, ' - Exclude ', CTE2A.exclusions)
        when CTE2A.exclusions is null and CTE2B.extras is not null then concat(pizza_name, ' - Extra ', CTE2B.extras)
        when CTE2A.exclusions is not null and CTE2B.extras is not null then concat(pizza_name, ' - Exclude ', CTE2A.exclusions, ' - Extra ', CTE2B.extras)
    end as order_item,
    CTE.exclusions, 
    CTE.extras, 
    order_date
from CTE2A
join CTE2B
    on CTE2A.order_line = CTE2B.order_line and CTE2A.require = CTE2B.require
join CTE
    on CTE2A.order_line = CTE.order_line
join pizza_runner.pizza_names as PN 
    on CTE.pizza_id = PN.pizza_id 
order by CTE2A.order_line;

--5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
    --For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

with CTE as 
    (select 
        CO.*,
        row_number () over (order by order_id, pizza_id) as order_line
    from pizza_runner.customer_orders as CO),
CTE1 as -- Mình dùng CTE và subquery để đưa danh sách ingredient chính của 2 loại pizza vào trong truy vấn chính
    (select 
        pizza_id, 
        topping_id, 
        topping_name as ingredient
    from pizza_runner.pizza_toppings as PT 
    join 
            (select 
                pizza_id, 
                trim(value) as ingredient
            from pizza_runner.pizza_recipes
            cross apply string_split(toppings, ',') as ingredient)
            as subquery
        on PT.topping_id = subquery.ingredient),
CTE2 as
    (select 
        order_line, 
        order_id, 
        customer_id, 
        CTE.pizza_id, 
        pizza_name, 
        case 
            when charindex(cast(topping_id as varchar(max)), extras) > 0 then concat ('2x', ingredient)
            when charindex(cast(topping_id as varchar(max)), exclusions) > 0 then null
            else ingredient
            --Ở đoạn này, ban đầu mình sử dụng topping_id like % extras %/% exclusions % nhưng kết quả trả về không chính xác
            --Do đó mình quyết định sử dụng charindex để scan các topping_id này trong từng extras/exclusions
            --Mọi người cũng có thể sử dụng toán tử 'in' nếu có CTE đã break 2 cột extra và exclusion
        end as ingredient,
        CTE.order_date 
    from CTE
    join pizza_runner.pizza_names as PN
        on CTE.pizza_id = PN.pizza_id 
    join CTE1
        on CTE.pizza_id = CTE1.pizza_id)
select 
    order_line, 
    order_id, 
    customer_id, 
    pizza_id, 
    concat(pizza_name, ': ', string_agg(ingredient, ', ' ) within group (order by ingredient asc)) as ingredient_list 
                                                        -- dùng within group để sắp xếp các item được tổng hợp trong hàm string_agg
from CTE2
group by 
    order_line, 
    order_id, 
    customer_id, 
    pizza_id, 
    pizza_name
order by order_line;

--6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

with CTE1 as
    (select 
        pizza_id, 
        trim(value) as ingredient_id
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
select 
    ingredient, 
    sum(times_used) as times_used 
from CTE2
group by ingredient
order by times_used desc;
