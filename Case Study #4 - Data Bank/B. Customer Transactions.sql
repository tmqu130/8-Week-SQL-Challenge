--1. What is the unique count and total amount for each transaction type?

select 
  txn_type,
  count(*) as unique_count,
  sum(txn_amount) as total_amount
from customer_transactions
group by txn_type;

--2. What is the average total historical deposit counts and amounts for all customers?

with CTE as
  (select
    customer_id, 
    count(*) as total_count,
    sum(txn_amount) as total_amount
  from customer_transactions
  where txn_type = 'deposit'
  group by customer_id)
select
  avg(total_count) as avg_count,
  avg(total_amount) as avg_amount
from CTE;

--3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

with CTE as
  (select 
    format(txn_date, 'yyyy-MM') as month,
    customer_id,
    count(case when txn_type = 'deposit' then 1 else null end) as deposit,
    count(case when txn_type = 'withdrawal' then 1 else null end) as withdrawal,
    count(case when txn_type = 'purchase' then 1 else null end) as purchase
  from customer_transactions
  group by
    format(txn_date, 'yyyy-MM'),
    customer_id)
select 
  month,
  count(distinct customer_id) as customer_count
from CTE
where deposit > 1 and (withdrawal = 1 or purchase = 1)
group by month;

--4. What is the closing balance for each customer at the end of the month?

--Tinh closing balance cua 1 khach hang moi thang
--Sum theo thang, group by eomonth, customer, specify cho deposit = +, purchase/withdrawal = -
--Tinh tong luy tien theo end month

--Phan recursive cua recursive CTE khong cho phep su dung aggregate function/subquery
  --> Xac dinh ngay min/max truoc

select 
  min(txn_date) as min_date,
  max(txn_date) as max_date
from customer_transactions;

with CTE1 as
  (select
    eomonth(txn_date) as end_month,
    customer_id,
    sum(case 
      when txn_type = 'deposit' then txn_amount
      else - txn_amount
      end) as transactions
  from customer_transactions
  group by
    eomonth(txn_date),
    customer_id
  ),
CTE2 as
  (select distinct
    customer_id,
    eomonth('2020-01-01') as month
  from customer_transactions
  
  union all
  
  select 
    customer_id,
    eomonth(dateadd(month, 1, month)) as month
  from CTE2
    where dateadd(month, 1, month) <= eomonth('2020-04-28'))

select
  CTE2.customer_id,
  month,
  isnull(transactions, 0) as transactions,
  sum(transactions) over(partition by CTE2.customer_id order by month) as closing_balance
from CTE1
right join CTE2
  on CTE1.customer_id = CTE2.customer_id
  and CTE1.end_month = CTE2.month
order by
  CTE2.customer_id,
  month;

--5. What is the percentage of customers who increase their closing balance by more than 5%?

with CTE1 as
  (select
    eomonth(txn_date) as end_month,
    customer_id,
    sum(case 
      when txn_type = 'deposit' then txn_amount
      else - txn_amount
      end) as transactions
  from customer_transactions
  group by
    eomonth(txn_date),
    customer_id
  ),
CTE2 as
  (select distinct
    customer_id,
    eomonth('2020-01-01') as month
  from customer_transactions
  
  union all
  
  select 
    customer_id,
    eomonth(dateadd(month, 1, month)) as month
  from CTE2
    where dateadd(month, 1, month) <= eomonth('2020-04-28')),
CTE3 as
  (select
    CTE2.customer_id,
    month,
    isnull(transactions, 0) as transactions,
    sum(transactions) over(partition by CTE2.customer_id order by month) as closing_balance
  from CTE1
  right join CTE2
    on CTE1.customer_id = CTE2.customer_id
    and CTE1.end_month = CTE2.month),
CTE4 as
  (select 
    *,
    lag(closing_balance) over(partition by customer_id order by month) as last_month_balance
  from CTE3)
select 
  *,
  (closing_balance - last_month_balance)/cast(last_month_balance as float) * 100 as increase_rate
into temp
from CTE4
where last_month_balance <> 0
and last_month_balance is not null;

select * from temp;

select 
  (count(distinct customer_id)
  /
  cast((select count(distinct customer_id) from temp) as float)
  ) * 100 as customer_proportion
from temp
where increase_rate > 5;
