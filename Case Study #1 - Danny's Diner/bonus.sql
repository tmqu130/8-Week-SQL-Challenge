--bonus questions:

--join all the things:

select 
    S.customer_id,
    order_date, 
    product_name, 
    price, 
    case
        when (order_date < join_date) or (join_date is null) then 'N'
        else 'Y'
    end as member
into join_sales
from sales as S 
join menu as M 
    on S.product_id = M.product_id
left join members as MS 
    on S.customer_id = MS.customer_id;

select * from join_sales;

--rank all the things: 

select 
    *, 
    case
        when member = 'N' then NULL
        when member = 'Y' then rank() over(partition by customer_id, member order by order_date asc)
    end as ranking
into rank_sales
from join_sales;

select * from rank_sales;
