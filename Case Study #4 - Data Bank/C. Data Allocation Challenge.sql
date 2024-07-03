--To test out a few different hypotheses -
--The Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

--Option 1: data is allocated based off the amount of money at the end of the previous month
--Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
--Option 3: data is updated real-time

--For this multi-part challenge question -
--You have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

  --running customer balance column that includes the impact each transaction
  --customer balance at the end of each month
  --minimum, average and maximum values of the running balance for each customer

--Using all of the data available - how much data would have been required for each option on a monthly basis?

--"Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts."

--(1) running customer balance column that includes the impact each transaction:

select
  customer_id,
  txn_date,
  sum(case
      when txn_type = 'deposit' then txn_amount
      else - txn_amount
    end
  ) over(partition by customer_id order by txn_date) as running_balance
from customer_transactions;

--(2) customer balance at the end of each month:

with CTE1 as
  (select distinct
    customer_id,
    eomonth('2020-01-01') as month_end
  from customer_transactions
  
  union all
  
  select
    customer_id,
    eomonth(dateadd(month, 1, month_end)) as month_end
  from CTE1
  where dateadd(month, 1, month_end) <= eomonth('2020-04-28')),
CTE2 as 
  (select 
    customer_id,
    eomonth(txn_date) as month_end,
    sum(case
      when txn_type = 'deposit' then txn_amount
      else - txn_amount
      end
    ) as total_amount
  from customer_transactions
  group by
    customer_id,
    eomonth(txn_date))
select
  A.customer_id,
  A.month_end,
  sum(total_amount) over(partition by A.customer_id order by A.month_end) as closing_balance
from CTE1 as A
left join CTE2 as B
  on A.customer_id = B.customer_id
  and A.month_end = B.month_end;

--(3) minimum, average and maximum values of the running balance for each customer:

with CTE1 as
  (select distinct
    customer_id,
    eomonth('2020-01-01') as month_end
  from customer_transactions
  
  union all
  
  select
    customer_id,
    eomonth(dateadd(month, 1, month_end)) as month_end
  from CTE1
  where dateadd(month, 1, month_end) <= eomonth('2020-04-28')),
CTE2 as 
  (select 
    customer_id,
    eomonth(txn_date) as month_end,
    sum(case
      when txn_type = 'deposit' then txn_amount
      else - txn_amount
      end
    ) as total_amount
  from customer_transactions
  group by
    customer_id,
    eomonth(txn_date)),
CTE3 as
  (select
    A.customer_id,
    A.month_end,
    sum(total_amount) over(partition by A.customer_id order by A.month_end) as closing_balance
  from CTE1 as A
  left join CTE2 as B
    on A.customer_id = B.customer_id
    and A.month_end = B.month_end)
select
  customer_id,
  min(closing_balance) as min_balance,
  avg(closing_balance) as avg_balance,
  max(closing_balance) as max_balance
from CTE3
group by customer_id;

--(1) Option 1: data is allocated based off the amount of money at the end of the previous month:

with MaxDate as (
  select eomonth(max(txn_date)) as max_month_end
  from customer_transactions
),
Total as (
  select 
    customer_id,
    eomonth(txn_date) as month_end,
    sum(case
      when txn_type = 'deposit' then txn_amount
      else - txn_amount
      end
    ) as total_amount
  from customer_transactions
  group by
    customer_id,
    eomonth(txn_date)
),
LastMonthData as (
  select
    T.customer_id,
    format(T.month_end, 'yyyy-MM') as month,
    case
      when sum(T.total_amount) over(partition by T.customer_id order by T.month_end) > 0
      then sum(T.total_amount) over(partition by T.customer_id order by T.month_end)
      else 0
      end as data_required
  from Total as T
  where T.month_end = (select max_month_end from MaxDate)
)
select *
from LastMonthData

union all

select distinct
  C.customer_id,
  format((select max_month_end from MaxDate), 'yyyy-MM') as month,
  0 as data_required
from customer_transactions as C
where C.customer_id not in (select customer_id from LastMonthData)
order by customer_id;

--(2) Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days:

with max_txn_date as (
  select max(txn_date) as max_date
  from customer_transactions
),
daily_balances as (
  select 
    customer_id,
    txn_date,
    sum(case 
      when txn_type = 'deposit' then txn_amount 
      else -txn_amount 
    end) over (partition by customer_id order by txn_date rows 30 preceding) as daily_balance
  from customer_transactions
)
select 
  customer_id,
  case 
    when avg(daily_balance) < 0 then 0 
    else avg(daily_balance) 
  end as avg_daily_balance
from daily_balances
cross join max_txn_date
where datediff(day, txn_date, max_date) <= 30
group by customer_id

union all

select distinct
  c.customer_id,
  0 as avg_daily_balance
from customer_transactions as c
where not exists (
  select 1
  from daily_balances db
  cross join max_txn_date
  where db.customer_id = c.customer_id
  and datediff(day, db.txn_date, max_date) <= 30
)
order by customer_id;

--(3) Option 3: data is updated real-time:

--Create a new table to collect real-time data needed:

create table data_allocation (
    customer_id int primary key,
    data_required float
);

--Create a trigger so whenever there is a new transaction, the data required changes accordingly:

create trigger update_data_allocation
on customer_transactions
after insert, update
as
begin
    update data_allocation
    set data_required = (
        select isnull(sum(
            case 
                when txn_type = 'deposit' then txn_amount
                else -txn_amount
            end
        ), 0)
        from customer_transactions
        where customer_transactions.customer_id = data_allocation.customer_id
    )
    from data_allocation
    join inserted i 
      on data_allocation.customer_id = i.customer_id;
    
    insert into data_allocation (customer_id, data_required)
    select i.customer_id,
        sum(
            case 
                when i.txn_type = 'deposit' then i.txn_amount
                else -i.txn_amount
            end
        )
    from inserted i
    left join data_allocation cda 
      on i.customer_id = cda.customer_id
    where cda.customer_id is null
    group by i.customer_id;
end;
GO

--Using all of the data available - how much data would have been required for each option on a monthly basis?

--Option 1:

with months as (
  select distinct 
    customer_id, 
    eomonth('2020-01-01') as month_end
  from customer_transactions

  union all

  select 
    customer_id, 
    eomonth(dateadd(month, 1, month_end)) as month_end
  from months
  where dateadd(month, 1, month_end) <= eomonth('2020-04-28')
),
monthly_balances as (
  select 
    customer_id, 
    eomonth(txn_date) as month_end,
    sum(case 
      when txn_type = 'deposit' then txn_amount 
      else - txn_amount 
      end) as total_amount
  from customer_transactions
  group by 
    customer_id, 
    eomonth(txn_date)
),
running_balances as (
  select 
    a.customer_id, 
    a.month_end,
    sum(total_amount) over (partition by a.customer_id order by a.month_end) as closing_balance
  from months as a
  left join monthly_balances as b
    on a.customer_id = b.customer_id 
    and a.month_end = b.month_end
)
select 
  format(month_end, 'yyyy-MM') as month,
  sum(case 
    when closing_balance > 0 then closing_balance 
    else 0 
    end) as data_required
from running_balances
group by month_end;

--Option 2:

with daily_balances as (
  select 
    customer_id,
    txn_date,
    sum(case 
      when txn_type = 'deposit' then txn_amount 
      else -txn_amount 
    end) over (partition by customer_id order by txn_date rows 30 preceding) as daily_balance
  from customer_transactions
),
monthly_balances as (
  select 
    customer_id,
    eomonth(txn_date) as month_end,
    avg(case 
      when daily_balance > 0 then daily_balance 
      else 0 
    end) as avg_monthly_balance
  from daily_balances
  group by 
    customer_id, 
    eomonth(txn_date)
)
select 
  format(month_end, 'yyyy-MM') as month,
  sum(avg_monthly_balance) as data_required
from monthly_balances
group by month_end
order by month_end;
