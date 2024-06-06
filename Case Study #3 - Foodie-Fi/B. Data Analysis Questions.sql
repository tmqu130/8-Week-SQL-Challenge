--B. Data Analysis Questions:

--1. How many customers has Foodie-Fi ever had?

select count(distinct customer_id) as customer_number
from foodie_fi.subscriptions;

--2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

select 
    format(start_date, 'yyyy-MM-01') as month_start, 
    count(*) as customer_number
from foodie_fi.subscriptions as S
join foodie_fi.plans as P
    on S.plan_id = P.plan_id
where plan_name = 'trial'
group by format(start_date, 'yyyy-MM-01')
order by format(start_date, 'yyyy-MM-01');

--3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

alter table foodie_fi.plans
alter column plan_name varchar(15);

select 
    plan_name, 
    count(*) as events_count
from foodie_fi.subscriptions as S 
join foodie_fi.plans as P 
    on S.plan_id = P.plan_id
where year(start_date) > 2020
group by plan_name
order by 
    case 
        when plan_name = 'basic monthly' then 1
        when plan_name = 'pro monthly' then 2
        when plan_name = 'pro annual' then 3
        else 4
    end;

--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

with CTE as 
    (select 
        (
            select count(distinct customer_id) 
            from foodie_fi.subscriptions
        ) as customer_count,
        (
            select count(distinct customer_id)
            from foodie_fi.subscriptions as S
            join foodie_fi.plans as P 
                on S.plan_id = P.plan_id
            where plan_name = 'churn'
        ) as churn_customer_count)
select 
    churn_customer_count,
    round(cast(churn_customer_count as float)/cast(customer_count as float)*100, 1) as churn_percentage
from CTE;

--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

with CTE as 
    (select 
        (
            select count(distinct customer_id)
            from foodie_fi.subscriptions
        ) as customer_count,
        (
            select count(distinct customer_id)
            from foodie_fi.subscriptions
            where customer_id not in (
                                    select customer_id
                                    from foodie_fi.subscriptions as S 
                                    join foodie_fi.plans as P 
                                        on S.plan_id = P.plan_id
                                    where plan_name in ('basic monthly', 'pro monthly', 'pro annual')
                                    )
        ) as churn_straight_customer_count
    ) 
select 
    churn_straight_customer_count,
    round(cast(churn_straight_customer_count as float)/cast(customer_count as float)*100, 0) as churn_percentage
from CTE;

--6. What is the number and percentage of customer plans after their initial free trial?

with CTE as 
    (select 
        plan_name, 
        count(distinct customer_id) as conversion_count
    from 
        (select 
            S.*, plan_name, 
            row_number() over(partition by customer_id order by start_date) as plan_order
        from foodie_fi.subscriptions as S
        join foodie_fi.plans as P 
            on S.plan_id = P.plan_id)
    as subquery
    where 
        customer_id not in (
                            select customer_id
                            from foodie_fi.subscriptions
                            where (plan_order = 1 and plan_name <> 'trial')
                            )
        and plan_order = 2
    group by plan_name)
select 
    plan_name,
    conversion_count,
    round(
            (cast(conversion_count as float)
            /
            (
                select cast(sum(conversion_count) as float)
                from CTE)
        * 100), 1
        ) as conversion_percent
from CTE
order by 
    case 
        when plan_name = 'basic monthly' then 1
        when plan_name = 'pro monthly' then 2
        when plan_name = 'pro annual' then 3
        else 4
    end;

--7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

with CTE as
    (select     
        S.customer_id, 
        plan_name, 
        start_date, 
        row_number() over(partition by S.customer_id order by start_date desc) as plan_order
    from foodie_fi.subscriptions as S 
    join 
        (select 
            customer_id, 
            max(start_date) as last_day_2020
        from foodie_fi.subscriptions
        where start_date <= '2020-12-31'
        group by customer_id)
    as subquery
        on S.customer_id = subquery.customer_id and S.start_date = last_day_2020
    join foodie_fi.plans as P 
        on S.plan_id = P.plan_id)
select 
    plan_name, 
    round(
            (cast(count(customer_id) as float))
            /
            (
                select cast(count(customer_id) as float) 
                from CTE
                where plan_order = 1
            )
        * 100, 1
        ) as plan_percentage
from CTE
group by plan_name
order by 
    case 
        when plan_name = 'trial' then 1
        when plan_name = 'basic monthly' then 2
        when plan_name = 'pro monthly' then 3
        when plan_name = 'pro annual' then 4
        else 5
    end;

--8. How many customers have upgraded to an annual plan in 2020?

select count(customer_id) as annual_plan_2020_count
from 
    (
        select 
            customer_id, 
            plan_name,
            start_date, 
            row_number () over (partition by customer_id order by start_date) as plan_order
        from foodie_fi.subscriptions as S
        join foodie_fi.plans as P 
            on S.plan_id = P.plan_id
    ) as subquery
where 
    plan_name = 'pro annual' 
    and plan_order <> 1 
    and year(start_date) = 2020;

--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

select avg(datediff(day, S1.start_date, S2.start_date)) as avg_days_to_annual_upgrade
from foodie_fi.subscriptions as S1
join 
    (select 
        customer_id, 
        min(start_date) as soonest_day
    from foodie_fi.subscriptions
    group by customer_id)
as subquery 
    on S1.customer_id = subquery.customer_id
        and S1.start_date = soonest_day
join foodie_fi.subscriptions as S2 
    on S1.customer_id = S2.customer_id
        and S1.start_date < S2.start_date
join foodie_fi.plans as P   
    on S2.plan_id = P.plan_id
where plan_name = 'pro annual';

--10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

select max(datediff(day, S1.start_date, S2.start_date)) as max_days_to_annual_upgrade
from foodie_fi.subscriptions as S1
join 
    (select 
        customer_id, 
        min(start_date) as soonest_day
    from foodie_fi.subscriptions
    group by customer_id)
as subquery 
    on S1.customer_id = subquery.customer_id
        and S1.start_date = soonest_day
join foodie_fi.subscriptions as S2 
    on S1.customer_id = S2.customer_id
        and S1.start_date < S2.start_date
join foodie_fi.plans as P   
    on S2.plan_id = P.plan_id
where plan_name = 'pro annual';

with CTE as
    (select datediff(day, S1.start_date, S2.start_date) as days_to_annual_upgrade
    from foodie_fi.subscriptions as S1
    join 
        (select 
            customer_id, 
            min(start_date) as soonest_day
        from foodie_fi.subscriptions
        group by customer_id)
    as subquery
        on S1.customer_id = subquery.customer_id
            and S1.start_date = soonest_day
    join foodie_fi.subscriptions as S2 
        on S1.customer_id = S2.customer_id
            and S1.start_date < S2.start_date
    join foodie_fi.plans as P   
        on S2.plan_id = P.plan_id
    where plan_name = 'pro annual')
select 
    days_bracket, 
    count(*) as customer_number
from 
    (select 
        case
            when days_to_annual_upgrade <= 30 then '0-30 days'
            when days_to_annual_upgrade between 31 and 60 then '31-60 days'
            when days_to_annual_upgrade between 61 and 90 then '61-90 days'
            when days_to_annual_upgrade between 91 and 120 then '91-120 days'
            when days_to_annual_upgrade between 121 and 150 then '121-150 days'
            when days_to_annual_upgrade between 151 and 180 then '151-180 days'
            when days_to_annual_upgrade between 181 and 210 then '181-210 days'
            when days_to_annual_upgrade between 211 and 240 then '211-240 days'
            when days_to_annual_upgrade between 241 and 270 then '241-270 days'
            when days_to_annual_upgrade between 271 and 300 then '271-300 days'
            when days_to_annual_upgrade between 301 and 330 then '301-330 days'
            else '331-360 days'
        end as days_bracket,
           case
                when days_to_annual_upgrade <= 30 then 1
                when days_to_annual_upgrade between 31 and 60 then 2
                when days_to_annual_upgrade between 61 and 90 then 3
                when days_to_annual_upgrade between 91 and 120 then 4
                when days_to_annual_upgrade between 121 and 150 then 5
                when days_to_annual_upgrade between 151 and 180 then 6
                when days_to_annual_upgrade between 181 and 210 then 7
                when days_to_annual_upgrade between 211 and 240 then 8
                when days_to_annual_upgrade between 241 and 270 then 9
                when days_to_annual_upgrade between 271 and 300 then 10
                when days_to_annual_upgrade between 301 and 330 then 11
                else 12
            end as bracket_order
    from CTE)
as subquery
group by 
    days_bracket, 
    bracket_order
order by bracket_order;

--11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

select count(*) as downgrade_customer_2020_count
from foodie_fi.subscriptions as S1 
join foodie_fi.subscriptions as S2 
    on S1.customer_id = S2.customer_id
        and S1.start_date > S2.start_date
where S1.plan_id = (select plan_id 
                    from foodie_fi.plans
                    where plan_name = 'pro monthly')
    and S2.plan_id = (select plan_id 
                    from foodie_fi.plans
                    where plan_name = 'basic monthly')
    and year(S1.start_date) = 2020
    and year(S2.start_date) = 2020;
