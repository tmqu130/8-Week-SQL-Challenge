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

--idea: mỗi record trong bảng sales đại diện cho 1 order của 1 khách hàng, và tương ứng với 1 món ăn duy nhất, do đó mình join bảng sales và bảng menu chứa giá các món ăn, và nhóm tổng giá trị cột price 
--tương ứng với món ăn được order trong bảng sales theo cột khách hàng (customer_id)

select customer_id, sum(price) as total_amount
from sales as S
join menu as M
    on S.product_id = M.product_id
group by customer_id
order by customer_id;

--2. How many days has each customer visited the restaurant?

--idea: đếm và nhóm cột order_date theo customer_id, điểm cần lưu ý ở đây là 1 ngày (order_date) của 1 khách hàng có thể tương ứng với nhiều record (1 ngày order nhiều lần hoặc 1 lần order nhiều món), nên
--hàm count phải kết hợp với distinct để tránh đếm trùng 1 order_date

select customer_id, count(distinct order_date) as visit_days
from sales
group by customer_id
order by customer_id;

--3. What was the first item from the menu purchased by each customer?

--idea: mình dùng hàm row_number để đánh số các order line theo thứ tự order date tăng dần, nhóm bằng mỗi khách hàng và gán kết quả vào 1 CTE, từ đó trong truy vấn chính, chọn ra các order line có thứ tự
--order xếp thứ 1 của mỗi khách hàng

with CTE as
    (select customer_id, S.product_id, product_name, row_number() over (partition by customer_id order by order_date asc) as order_sequence
    from sales as S
    join menu as M 
        on S.product_id = M.product_id)
select customer_id, product_id, product_name
from CTE
where order_sequence = 1;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

--idea: mình tạo 1 CTE để tính số lượt order của mỗi món ăn, rồi trong truy vấn chính đặt điều cho số lượt order bằng số lần order tối đa (hàm max) trong 1 subquery cũng lấy giá trị từ CTE

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

--idea: trước tiên mình sử dụng 1 CTE để đếm số lần xuất hiện của từng món ăn, nhóm theo cả khách hàng và món ăn, sau đó sử dụng 1 CTE khác để tìm ra giá trị lớn nhất (hàm max) của cột số lần xuất hiện đó
--nhóm theo mã khách hàng, và cuối cùng trong truy vấn chính tìm ra tên món ăn có số lần xuất hiện bằng số lần xuất hiện nhiều nhất tương ứng với mỗi khách hàng

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

--idea: mình hiểu đề bài này theo 2 hướng: chỉ chọn 1 sản phẩm đầu tiên theo thứ tự mặc định, hoặc tất cả sản phẩm được order cùng trong ngày đầu tiên đó, với mỗi hướng hiểu mình sử dụng 1 cách khác nhau:

--mình sử dụng hàm row_number để xếp thứ tự các order_date (nhóm theo mã khách hàng) tăng dần, với điều kiện là ngày order phải cùng hoặc sau ngày tham gia member, rồi chọn đơn hàng có ngày xếp đầu tiên:
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

--với cách trên, các row sẽ được đánh số theo thứ tự mà không cân nhắc đến giá trị, để tìm ra tất cả các món ăn được đặt trong cùng ngày đó, mình thay thế hàm row_number bằng hàm rank:
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
--idea: mình thực hiện yêu cầu này gần giống hệt như yêu cầu 6, 2 điểm khác nhau ở đây là order_date phải sớm hơn join_date, và cho thứ tự order_date giảm dần để chọn ra ngày gần ngày tham gia member nhất:

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
--idea: mình sẽ tính count(product_id) và sum(price), nhóm theo mã khách hàng, với điều kiện order_date trước join_date

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

--idea: trước tiên mình có 1 CTE để tạo 1 cột point để tính ra điểm tương ứng của từng món, chia trường hợp bằng case when với point = price*10, các record có món ăn là sushi thì point = price*20
--sau đó dùng hàm sum tính tổng điểm, nhóm theo mã khách hàng

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

--idea: có nhiều cách để thực hiện yêu cầu, sau đây là cách mình thấy logic mạch lạc và dễ hiểu nhất:
--trước tiên mình tạo CTE1, lưu trữ các thông tin cần thiết từ cả 3 bảng, với điều kiện cơ bản là right join bảng member để loại customer C không có membership, và ngày order phải trong tháng 1
--sau đó từ 1 "bảng tổng hợp" là CTE1, mình sử dụng 2 CTE 2 và 3 chia thành 2 trường hợp lần lượt là: cách tính điểm đặc biệt (1 tuần sau join_date) và cách tính điểm bình thường
--CTE2 tính toán điểm của các order line 1 tuần sau khi khi đăng ký membership, điều kiện bằng hàm datediff, với point của tất cả order line đều bằng price*20
--CTE3 tính điểm các order line bình thường, không hưởng ưu đãi, tức điều kiện cho order_date sẽ là trước join_date, hoặc sau join_date 1 tuần 
--sau đó mình tạo thêm 1 CTE nữa để kết hợp dữ liệu của 2 trường hợp rồi dùng nó để tính tổng điểm với hàm sum theo từng customer_id
--đây là cách mình muốn trình bày, do việc chia các trường hợp thành các CTE khiến cho người đọc nhìn vào code là có thể hiểu ý tưởng của người viết
--nếu thấy viết nhiều CTE là quá dài dòng, các bạn có thể sử dụng case when để chia trường hợp
--nhưng nhìn chung, với những bài yêu cầu chia nhiều trường hợp như này, việc quan trọng nhất là để ý không tính xót trường hợp nào, và các điều kiện phải thật chính xác

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
--idea: kết hợp các bảng và select into vào 1 bảng mới, lưu ý phải sử dụng sales left join members để giữ được các record của customer 'C', đồng thời tạo 1 column sử dụng câu lệnh case when thể hiện membership

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
--idea: từ bảng mới tạo ở trên, thêm 1 cột ranking, sắp xếp thứ tự order line theo order_date của từng khách hàng sau khi trở thành member, trường hợp ngược lại sẽ có giá trị NULL
--theo như kết quả mẫu, việc sử dụng rank hoặc dense_rank trong trường hợp dataset Danny's Diner đều cho ra kết hợp như nhau

select *, case
            when member = 'N' then NULL
            when member = 'Y' then rank() over(partition by customer_id, member order by order_date asc)
        end as ranking
into new_sales2
from new_sales;

select * from new_sales2;