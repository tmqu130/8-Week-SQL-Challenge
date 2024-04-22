create table sales (
    customer_id varchar(1),
    order_date date,
    product_id int
);

create table members (
    customer_id varchar(1),
    join_date date
);

create table menu (
    product_id int,
    product_name varchar (5),
    price int
);

insert into sales
values 
    ('A', '2021-01-01',	1),
    ('A', '2021-01-01',	2),
    ('A', '2021-01-07',	2),
    ('A', '2021-01-10',	3),
    ('A', '2021-01-11',	3),
    ('A', '2021-01-11',	3),
    ('B', '2021-01-01',	2),
    ('B', '2021-01-02',	2),
    ('B', '2021-01-04',	1),
    ('B', '2021-01-11',	1),
    ('B', '2021-01-16',	3),
    ('B', '2021-02-01',	3),
    ('C', '2021-01-01',	3),
    ('C', '2021-01-01',	3),
    ('C', '2021-01-07',	3);

insert into menu
VALUES
(1, 'sushi', 10),
(2,	'curry', 15),
(3, 'ramen', 12);

insert into members
VALUES
('A', '2021-01-07'),
('B', '2021-01-09');

alter table menu
alter column product_id int not null;

alter table menu
add primary key (product_id);

alter table sales
add foreign key (product_id) references menu (product_id);

--1. What is the total amount each customer spent at the restaurant?

select customer_id, sum(price) as total_amount
from sales as S
join menu as M
    on S.product_id = M.product_id
group by customer_id
order by customer_id;

--2. How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) as visit_days
from sales
group by customer_id
order by customer_id;

--3. What was the first item from the menu purchased by each customer?

with CTE as
    (select customer_id, S.product_id, product_name, row_number() over (partition by customer_id order by order_date asc) as order_sequence
    from sales as S
    join menu as M 
        on S.product_id = M.product_id)
select customer_id, product_id, product_name
from CTE
where order_sequence = 1;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

with CTE as
    (select S.product_id, product_name, count(*) as purchase_times
    from sales as S
    join menu as M
        on S.product_id = M.product_id
    group by S.product_id, product_name)
select product_id, product_name, purchase_times 
from CTE
where purchase_times = (select max(purchase_times) from CTE);

--5. Which item was the most popular for each customer?

with CTE1 as 
    (select customer_id, S.product_id, product_name, count(S.product_id) as purchase_times_1
    from sales as S
    join menu as M
        on S.product_id = M.product_id
    group by customer_id, S.product_id, product_name),
CTE2 as
    (select customer_id, max(purchase_times_1) as purchase_times_2
    from CTE1
    group by customer_id)
select CTE1.customer_id, CTE1.product_id, CTE1.product_name, purchase_times_1 as purchase_times
from CTE1
join CTE2 
    on CTE1.customer_id = CTE2.customer_id and CTE1.purchase_times_1 = CTE2.purchase_times_2
order by CTE1.customer_id;

--6. Which item was purchased first by the customer after they became a member?

with CTE as
    (select MS.customer_id, S.product_id, product_name, row_number() over (partition by MS.customer_id order by order_date asc) as order_sequence
    from sales as S
    join menu as M 
        on S.product_id = M.product_id
    right join members as MS 
        on S.customer_id = MS.customer_id
    where order_date >= join_date)
select customer_id, product_id, product_name
from CTE
where order_sequence = 1;

with CTE as
    (select MS.customer_id, S.product_id, product_name, rank() over (partition by MS.customer_id order by order_date asc) as order_sequence
    from sales as S
    join menu as M 
        on S.product_id = M.product_id
    right join members as MS 
        on S.customer_id = MS.customer_id
    where order_date >= join_date)
select customer_id, product_id, product_name
from CTE
where order_sequence = 1;

--7. Which item was purchased just before the customer became a member?

with CTE as
    (select MS.customer_id, S.product_id, product_name, row_number() over (partition by MS.customer_id order by order_date desc) as order_sequence
    from sales as S
    join menu as M 
        on S.product_id = M.product_id
    right join members as MS 
        on S.customer_id = MS.customer_id
    where order_date < join_date)
select customer_id, product_id, product_name
from CTE
where order_sequence = 1;

with CTE as
    (select MS.customer_id, S.product_id, product_name, rank() over (partition by MS.customer_id order by order_date desc) as order_sequence
    from sales as S
    join menu as M 
        on S.product_id = M.product_id
    right join members as MS 
        on S.customer_id = MS.customer_id
    where order_date < join_date)
select customer_id, product_id, product_name
from CTE
where order_sequence = 1;

--8. What is the total items and amount spent for each member before they became a member?

select MS.customer_id, count(S.product_id) as total_items_before_member, sum(price) as total_amount_before_member
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
    (select customer_id, S.product_id, product_name, case
        when product_name = 'sushi' then (price*20)
        else (price*10) 
        end as point
    from sales as S
    join menu as M
        on S.product_id = M.product_id)
select customer_id, sum(point) as customer_point
from CTE
group by customer_id;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with CTE1 as
    (select S.customer_id, S.product_id, product_name, price, order_date, join_date
    from sales as S
    join menu as M
        on S.product_id = M.product_id
    right join members as MS
        on S.customer_id = MS.customer_id
    where month(order_date) = 1),
CTE2 as
    (select customer_id, (price*20) as point
    from CTE1
    where order_date >= join_date and datediff(day, join_date, order_date) <= 6),
CTE3 as
    (select customer_id, case
        when product_name = 'sushi' then (price*20)
        else (price*10)
        end as point
    from CTE1
    where (order_date < join_date) or order_date >= join_date and datediff(day, join_date, order_date) > 6),
CTE4 as
    (select * from CTE2
    union all
    select * from CTE3)
select customer_id, sum(point) as customer_point
from CTE4
group by customer_id;

--bonus questions:

--join all the things:

select S.customer_id, order_date, product_name, price, case
    when (order_date < join_date) or (join_date is null) then 'N'
    else 'Y'
    end as member
into new_sales
from sales as S 
join menu as M 
    on S.product_id = M.product_id
left join members as MS 
    on S.customer_id = MS.customer_id;

--rank all the things: 

select *, case
            when member = 'N' then NULL
            when member = 'Y' then rank() over(partition by customer_id, member order by order_date asc)
        end as ranking
into new_sales2
from new_sales;

select * from new_sales2;
