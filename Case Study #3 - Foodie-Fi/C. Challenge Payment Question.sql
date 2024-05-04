--C. Challenge Payment Question

--The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer 
--in the subscriptions table with the following requirements:

--monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
--upgrades from basic to pro plans are reduced by the current paid amount in that month and start immediately
--upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
--once a customer churns they will no longer make payments

with CTE as
    (select 
        customer_id,
        S.plan_id,
        plan_name,
        start_date as payment_date,
        case
            when lead(start_date) over (partition by customer_id order by start_date) is null then '2020-12-31'
            else lead(start_date) over (partition by customer_id order by start_date)
        end as last_date,
        case
            when lag(plan_name) over (partition by customer_id order by start_date) = 'basic monthly' 
                and plan_name in ('pro monthly', 'pro annual')
            then (price - lag(price) over (partition by customer_id order by start_date))
            else price
        end as amount
    from foodie_fi.subscriptions as S
    join foodie_fi.plans as P 
        on S.plan_id = P.plan_id
    where plan_name not in ('trial', 'churn')
        and year(start_date) = 2020
    
    union all

    select
        customer_id,
        plan_id,
        plan_name,
        dateadd (month, 1, payment_date) 
            as payment_date,
        last_date, 
        amount
    from CTE
    where dateadd (month, 1, payment_date) < last_date
        and plan_name <> 'pro annual')

select
    *,
    row_number() over (partition by customer_id order by payment_date) 
        as payment_order
into foodie_fi.payments_2020
from CTE
where amount is not null
order by customer_id;

select * from foodie_fi.payments_2020;
