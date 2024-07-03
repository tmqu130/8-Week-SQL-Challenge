--1. How many unique nodes are there on the Data Bank system?

select count(distinct node_id) as unique_nodes
from customer_nodes;

--2. What is the number of nodes per region?

select 
    R.region_id,
    region_name,
    count(node_id) as nodes_count
from regions as R
join customer_nodes as N
    on R.region_id = N.region_id
group by 
    R.region_id,
    region_name
order by R.region_id;

--3. How many customers are allocated to each region?

select 
    R.region_id,
    region_name,
    count(distinct customer_id) as customers_count
from regions as R
join customer_nodes as N
    on R.region_id = N.region_id
group by 
    R.region_id,
    region_name
order by R.region_id;

--4. How many days on average are customers reallocated to a different node?

with CTE as
  (select 
    *,
    lead(node_id) over(partition by customer_id order by start_date) as lead_node
  from customer_nodes
  where year(end_date) <> 9999)
select 
  avg(datediff(day, start_date, end_date)) + 1 as avg_interval
from CTE
where lead_node is not null
  and lead_node <> node_id;

--5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

with CTE as
  (select
    *,
    (datediff(day, start_date, end_date)) + 1 as interval
  from
    (select 
      *,
      lead(node_id) over(partition by customer_id order by start_date) as lead_node
    from customer_nodes
    where year(end_date) <> 9999)
  as subquery
  where lead_node is not null
    and lead_node <> node_id)
select distinct
  R.region_id, 
  region_name,
  percentile_cont(0.5) within group (order by interval) over (partition by R.region_id) as median,
  percentile_cont(0.8) within group (order by interval) over (partition by R.region_id) as pct_80,
  percentile_cont(0.95) within group (order by interval) over (partition by R.region_id) as pct_95
from CTE
join regions as R 
  on CTE.region_id = R.region_id;
