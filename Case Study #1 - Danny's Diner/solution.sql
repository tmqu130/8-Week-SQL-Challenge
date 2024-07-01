--1. What is the total amount each customer spent at the restaurant?

select 
    customer_id, 
    sum(price) as total_amount
from sales as S
join menu as M
    on S.product_id = M.product_id
group by customer_id
order by customer_id;

--2. How many days has each customer visited the restaurant?

select 
    customer_id, 
    count(distinct order_date) as visit_days
from sales
group by customer_id
order by customer_id;

--3. What was the first item from the menu purchased by each customer?

with CTE as
    (select 
        customer_id, 
        S.product_id, 
        product_name, 
        row_number() over (partition by customer_id order by order_date asc) as order_sequence
    from sales as S
    join menu as M 
        on S.product_id = M.product_id)
select customer_id, product_id, product_name
from CTE
where order_sequence = 1;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1
    M.product_id,
    product_name,
    count(*) as purchase_times
from menu as M 
join sales as S
    on M.product_id = S.product_id
group by 
    M.product_id,
    product_name
order by count(*) desc;

--5. Which item was the most popular for each customer?

with CTE as 
    (select 
        customer_id, 
        S.product_id, 
        product_name, 
        count(S.product_id) as purchase_times,
        rank() over (partition by customer_id order by count(S.product_id) desc) as purchase_rank
    from sales as S
    join menu as M
        on S.product_id = M.product_id
    group by 
        customer_id, 
        S.product_id, 
        product_name)
select 
    customer_id, 
    product_id, 
    product_name, 
    purchase_times
from CTE
where purchase_rank = 1
order by customer_id;

--6. Which item was purchased first by the customer after they became a member?

with CTE as
    (select 
        MS.customer_id, 
        S.product_id, 
        product_name, 
        rank() over (partition by MS.customer_id order by order_date asc) as order_sequence
    from sales as S
    join menu as M 
        on S.product_id = M.product_id
    right join members as MS 
        on S.customer_id = MS.customer_id
    where order_date >= join_date)
select  
    customer_id, 
    product_id, 
    product_name
from CTE
where order_sequence = 1;

--7. Which item was purchased just before the customer became a member?

with CTE as
    (select 
        MS.customer_id, 
        S.product_id, 
        product_name, 
        rank() over (partition by MS.customer_id order by order_date desc) as order_sequence
    from sales as S
    join menu as M 
        on S.product_id = M.product_id
    right join members as MS 
        on S.customer_id = MS.customer_id
    where order_date < join_date)
select 
    customer_id, 
    product_id, 
    product_name
from CTE
where order_sequence = 1;

--8. What is the total items and amount spent for each member before they became a member?

select 
    MS.customer_id, 
    count(S.product_id) as total_items_before_member, 
    sum(price) as total_amount_before_member
from sales as S 
join menu as M 
    on S.product_id = M.product_id
right join members as MS 
    on S.customer_id = MS.customer_id
where order_date < join_date
group by MS.customer_id
order by MS.customer_id;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with CTE as
    (select 
        customer_id, 
        S.product_id, 
        product_name, 
        case
            when product_name = 'sushi' then (price*20)
            else (price*10) 
        end as point
    from sales as S
    join menu as M
        on S.product_id = M.product_id)
select 
    customer_id, 
    sum(point) as customer_point
from CTE
group by customer_id;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with CTE1 as
    (select 
        S.customer_id, 
        S.product_id, 
        product_name, 
        price, 
        order_date,
        join_date
    from sales as S
    join menu as M
        on S.product_id = M.product_id
    right join members as MS
        on S.customer_id = MS.customer_id
    where month(order_date) = 1),
CTE2 as
    (select
        customer_id, 
        (price*20) as point
    from CTE1
    where 
        order_date >= join_date 
        and 
        datediff(day, join_date, order_date) <= 6
    
    union all

    select 
        customer_id, 
        case
            when product_name = 'sushi' then (price*20)
            else (price*10)
        end as point
    from CTE1
    where 
        (order_date < join_date) 
        or 
        order_date >= join_date and datediff(day, join_date, order_date) > 6)

select 
    customer_id, 
    sum(point) as customer_point
from CTE2
group by customer_id;
