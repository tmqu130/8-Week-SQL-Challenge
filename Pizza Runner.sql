create schema pizza_runner;
GO

create table pizza_runner.runners (
    runner_id int,
    registration_date date
);

insert into pizza_runner.runners
values 
    (1, '2021-01-01'),
    (2,	'2021-01-03'),
    (3,	'2021-01-08'),
    (4,	'2021-01-15');

create table pizza_runner.customer_orders (
    order_id int,
    customer_id int,
    pizza_id int,
    exclusions varchar(4),
    extras varchar(4),
    order_date datetime
);

insert into pizza_runner.customer_orders
values
    (1, 101, 1, '', '', '2021-01-01 18:05:02'),
    (2,	101, 1, '', '',	'2021-01-01 19:00:52'),
    (3,	102, 1, '', '', '2021-01-02 23:51:23'),
    (3,	102, 2, '', 'NaN', '2021-01-02 23:51:23'),
    (4,	103, 1,	'4', '', '2021-01-04 13:23:46'),
    (4,	103, 1,	'4', '', '2021-01-04 13:23:46'),
    (4,	103, 2,	'4', '', '2021-01-04 13:23:46'),
    (5, 104, 1, null, '1',	'2021-01-08 21:00:29'),
    (6,	101, 2,	null, null, '2021-01-08 21:03:13'),
    (7,	105, 2,	null, '1', '2021-01-08 21:20:29'),
    (8,	102, 1,	null, null,	'2021-01-09 23:54:33'),
    (9,	103, 1,	'4', '1, 5', '2021-01-10 11:22:59'),
    (10, 104, 1, null, null, '2021-01-11 18:34:49'),
    (10, 104, 1, '2, 6', '1, 4', '2021-01-11 18:34:49');

create table pizza_runner.runner_orders (
    order_id int,
    runner_id int,
    pickup_time varchar(19),
    distance varchar(7),
    duration varchar(10),
    cancellation varchar(23)
);

insert into pizza_runner.runner_orders
values
    (1,	1, '2021-01-01 18:15:34', '20km', '32 minutes', ''),	 
    (2,	1,	'2021-01-01 19:10:54', '20km', '27 minutes', ''),	 
    (3,	1, '2021-01-03 00:12:37', '13.4km',	'20 mins', 'NaN'),
    (4,	2, '2021-01-04 13:53:03', '23.4', '40', 'NaN'),
    (5,	3, '2021-01-08 21:10:57', '10', '15', 'NaN'),
    (6,	3, null, null, null, 'Restaurant Cancellation'),
    (7,	2, '2020-01-08 21:30:45', '25km', '25mins', null),
    (8,	2, '2020-01-10 00:15:02', '23.4 km', '15 minute', null),
    (9,	2, null, null, null, 'Customer Cancellation'),
    (10, 1,	'2020-01-11 18:50:20', '10km', '10minutes',	null);

create table pizza_runner.pizza_names (
    pizza_id int,
    pizza_name text
);

insert into pizza_runner.pizza_names
values
    (1, 'Meat Lovers'),
    (2, 'Vegetarian');

create table pizza_runner.pizza_recipes (
    pizza_id int,
    toppings text
);

insert into pizza_runner.pizza_recipes
values
    (1,	'1, 2, 3, 4, 5, 6, 8, 10'),
    (2,	'4, 6, 7, 9, 11, 12');

create table pizza_runner.pizza_toppings (
    topping_id int,
    topping_name text
);

insert into pizza_runner.pizza_toppings
values 
    (1, 'Bacon'),
    (2, 'BBQ Sauce'),
    (3,	'Beef'),
    (4,	'Cheese'),
    (5,	'Chicken'),
    (6,	'Mushrooms'),
    (7,	'Onions'),
    (8,	'Pepperoni'),
    (9,	'Peppers'),
    (10, 'Salami'),
    (11, 'Tomatoes'),
    (12, 'Tomato Sauce');

--Before you start writing your SQL queries however - you might want to investigate the data, 
--you may want to do something with some of those null values and data types in the customer_orders and runner_orders tables!

select * from pizza_runner.customer_orders;

--Trước tiên với bảng customer_orders, mình sẽ xử lý các giá trị trống, giá trị 'NaN' và giá trị NULL ở 2 cột exclusions và extras, đổi thành '0'
--Điều này ám chỉ các đơn hàng không ghi nhận thông tin ở 2 cột này có nghĩa là khách hàng không có yêu cầu đặc biệt

update pizza_runner.customer_orders
set exclusions = '0'
where exclusions = '' or exclusions is null;

update pizza_runner.customer_orders
set extras = '0'
where extras in ('', 'NaN') or extras is null;

select * from pizza_runner.runner_orders;

--Với bảng runner_orders, có một số vấn đề cần giải quyết như sau:

    --Xứ lý các giá trị Null ở các cột pickup_time, distance, duration và cancellation:
    --(1) Mình xử lý các giá trị trống, NaN và Null ở cột cancellation trước, bằng cách thay thế chúng bằng 'No':

    update pizza_runner.runner_orders
    set cancellation = 'No'
    where cancellation in ('', 'NaN') or cancellation is null;

    --(2) Ngoài ra mình cũng rút ngắn thông tin trong cột cancellation bằng function string_split:

    with X as
        (select order_id,
        (SELECT value FROM STRING_SPLIT(cancellation, ' ') WHERE value <> '' ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY) AS first_value
        FROM pizza_runner.runner_orders)
    update pizza_runner.runner_orders
    set cancellation = first_value
    from X
    join pizza_runner.runner_orders as RO 
        on X.order_id = RO.order_id;

    --(3) Tiếp đến, mục tiêu của mình là đă cột duration về dạng chỉ còn chứa số phút, loại bỏ các khoảng trắng và chữ (do tất cả record đều đã ở dạng phút)
    -- Ở đây có thể thấy các chữ mins/minutes có thể liền sát với số phút mà không có delimiter, do đó thay vì string_split, mình sẽ sử dụng trim và chia trường hợp:
    -- Các lần trước, mình xử lý giá trị null bằng cách thay bằng 'No' hoặc '0', tuy nhiên pickup_time, distance và duration là các cột định lượng, nên mình sẽ bỏ trống:

    update pizza_runner.runner_orders
    set duration = case 
        when duration is null then ''
        when duration like '%minutes' then trim ('minutes' from duration)
        when duration like '%mins%' then trim ('mins' from duration)
        when duration like '%minute%' then trim ('minute' from duration)
        else duration
    end;

    -- Tương tự với distance:

    update pizza_runner.runner_orders
    set distance = case 
        when distance is null then ''
        when distance like '%km' then trim ('km' from distance)
        else distance
    end;

    -- Với pickup_time thì chỉ cần thay thế giá trị null là được:

    update pizza_runner.runner_orders
    set pickup_time = ''
    where pickup_time is null;

    -- Và cuối cùng là đổi lại data type của các cột pickup_time, distance, duration để có thể dùng chúng tính toán:

    alter table pizza_runner.runner_orders
    alter column pickup_time datetime null;

    alter table pizza_runner.runner_orders
    alter column distance float null;

    alter table pizza_runner.runner_orders
    alter column duration int null;
    
    --Kiểm tra lại: 

    select * from pizza_runner.runner_orders;

    --Sau khi thay đổi data type, các cột có giá trị trống bị auto fill:
    --Cột pickup_time default là: '1900-01-01 00:00:00.000', còn distance và duration là '0'
    --Điều này xảy ra theo mình tìm hiểu là do các value type column (như datetime, float, int) không thể nhận giá trị blank hay null
    --Mình đã thực hiện nhiều cách như set data type các column này nullable, default null hoặc '' nhưng không hiệu quả và đành chấp nhận các giá trị default này
    --Ai biết có thể chia sẻ giúp mình được không

--A. PIZZA METRICS

--1. How many pizzas were ordered?
--Do mỗi order line trong bảng customer_orders chỉ tương ứng với 1 pizza duy nhất, nên ta chỉ cần count số dòng của bảng này:

select count(*) as pizza_ordered
from pizza_runner.customer_orders;

--2. How many unique customer orders were made?
--Nhiều order line có thể cùng đại diện cho 1 order_id, nên mình sẽ sử dụng count distinct order_id:

select count (distinct order_id) as order_number
from pizza_runner.customer_orders;

--3. How many successful orders were delivered by each runner?
--successful order là đơn hàng không bị cancel, vì thế mình sẽ count các row ở bảng runner_orders những record có cancellation là 'No', nhóm bằng runner_id:

select runner_id, count(*) as successful_order
from pizza_runner.runner_orders
where cancellation = 'No'
group by runner_id;

--4. How many of each type of pizza was delivered?
--Câu này mình sử dụng count (*) và group by pizza_id, đồng thời join thêm bảng pizza_names để xem tên các loại pizza
--Khi join 2 bảng, mình gặp lỗi vì data type ở cột pizza_name là text, vì thế không thể dùng chúng trong so sánh hay sắp xếp, nên mình sẽ đổi lại thành varchar
--Ngoài ra ở đây có 1 điểm cần lưu ý là đề bài yêu cầu tính pizza đã được deliver, tức chúng ta cần join thêm bảng runner_orders để loại bỏ các đơn bị cancel:

alter table pizza_runner.pizza_names
alter column pizza_name varchar(50);

select PN.pizza_id, pizza_name, count(*) as order_number
from pizza_runner.customer_orders as CO
left join pizza_runner.pizza_names as PN 
    on CO.pizza_id = PN.pizza_id
join pizza_runner.runner_orders as RO
    on CO.order_id = RO.order_id
where cancellation = 'No'
group by PN.pizza_id, pizza_name;

--5. How many Vegetarian and Meatlovers were ordered by each customer?
--Câu này cũng gần tương tự câu trên, mình group thêm customer_id nữa là được, và ở đây chỉ hỏi ordered thay vì delivered, nên mình sẽ select trên toàn bộ order:

select customer_id, pizza_name, count(*) as order_number
from pizza_runner.customer_orders as CO
left join pizza_runner.pizza_names as PN 
    on CO.pizza_id = PN.pizza_id
group by customer_id, pizza_name
order by customer_id;

--6. What was the maximum number of pizzas delivered in a single order?
--số lượng pizza mình cần tính là trên mỗi order, nên mình phải tạo 1 bảng để tính số lượng pizza theo từng order trước
--rồi sau đó mới dùng hàm max để để tìm số pizza lớn nhất trong 1 order:

with CTE AS
    (select order_id, count(*) as pizza_number
    from pizza_runner.customer_orders
    group by order_id)
select CTE.order_id, pizza_number as max_pizza_number
from CTE
join pizza_runner.runner_orders as RO 
    on CTE.order_id = RO.order_id
where cancellation = 'No' and
    pizza_number = (select max(pizza_number) from CTE);


--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
--Change ở đây là việc pizza được yêu cầu có thêm hoặc bớt topping (thể hiện ở cột exclusions và extras)
--> Mình sẽ chia case để count các trường hợp unchanged và changed, sau đó nhóm kết quả count theo customer_id:

select customer_id, 
    count(case when exclusions = '0' and extras = '0' then 1 end) as unchanged,
    count(case when exclusions <> '0' or extras <> '0' then 1 end) as changed
from pizza_runner.customer_orders as CO  
join pizza_runner.runner_orders as RO 
    on CO.order_id = RO.order_id
where cancellation = 'No'
group by customer_id;

--8. How many pizzas were delivered that had both exclusions and extras?
--Gần tương tự câu trên, chỉ khác là phải dùng toán tử 'and' để tìm trường hợp vừa có exclusions vừa có extra thay vì 'or':

select count(case when exclusions <> '0' and extras <> '0' then 1 end) as both_exclude_and_extra
from pizza_runner.customer_orders as CO  
join pizza_runner.runner_orders as RO 
    on CO.order_id = RO.order_id
where cancellation = 'No';

--9. What was the total volume of pizzas ordered for each hour of the day?
--Để tính số pizza order theo giờ, mình chỉ cần dùng datepart để lấy giờ ra từ cột order_date và group by datepart đó:

select datepart(hour, order_date) as order_hour, count(*) as pizza_order 
from pizza_runner.customer_orders
group by datepart(hour, order_date);

--10. What was the volume of orders for each day of the week?
--Tương tự, nhưng thay vì datepart mình sử dụng datename, hàm này sẽ trả về tên của ngày ở dạng chữ thay vì số, với argument đầu tiên là dw (day or week)

select datename (dw, order_date) as day_of_week, count(distinct order_id) as pizza_order
from pizza_runner.customer_orders
group by datename (dw, order_date), datepart (dw, order_date)
order by case   
    when datepart (dw, order_date) = 1 then 7
    else datepart (dw, order_date) - 1
    end;

--Ở đây mình vẫn sử dụng thêm datepart để set điều kiện cho cột ngày trong tuần bắt đầu từ thứ 2 thay vì chủ nhật (chủ yếu là để nó thuận mắt)

--B. Runner and Customer Experience

--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
--Yêu cầu này yêu cầu chúng ta nhóm registration_date theo tuần, và đếm số runner đăng ký mỗi tuần
--Do có vẻ như 2 ngày 1 và ngày 3 tháng 1 năm 2021 không nằm trong 1 tuần, nên mình sử dụng hàm datediff thay vì datepart
--Cách này sẽ giúp mình không tìm tuần 1 cách mặc định, mà tìm tuần theo interval là tuần giữa 2 ngày (ngày đăng ký và ngày 2021-01-01):

select (datediff(week, '2021-01-01', registration_date) + 1) as week, count(*) as regis_runner
from pizza_runner.runners
group by datediff(week, '2021-01-01', registration_date);

--Do 2 ngày đầu tiên cùng tuần, nên datediff sẽ cho ra kết quả = 0, do đó mình +1 thứ tự các tuần là số tự nhiên bắt đầu từ 1

--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
--Khoảng thời gian để runner tới Pizza Runner HQ sẽ là chênh lệch giữa pickup_time và order_date, mình dùng hàm datediff tính theo minute
--Nhớ loại bỏ các trường hợp đơn hàng bị hủy:

--Khi làm câu này và nhận về kết quả âm rất lớn, mình mới phát hiện là 1 số value ở cột pickup_time thuộc về năm 2020
--Mình sẽ đổi lại thành 2021 để phù hợp với context của dataset:

update pizza_runner.runner_orders
set pickup_time = dateadd (year, 1, pickup_time)
where pickup_time >= '2020-01-01' and pickup_time < '2021-01-01';

--Sau đó chạy lại code là ra kết quả:

with CTE as 
    (select distinct order_id, order_date
    from pizza_runner.customer_orders)
select avg(datediff(minute, order_date, pickup_time)) as avg_arrive_time
from CTE  
join pizza_runner.runner_orders as RO   
    on CTE.order_id = RO.order_id
where cancellation = 'No'; 

--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
--Đề yêu cầu tìm mối quan hệ giữa số pizza và thời gian để chuẩn bị order, tức khoảng thời gian giữa order time và pickup time, như ở câu trên:
--Mình sẽ dùng CTE để tìm số lượng pizza của các order trước, rồi tính trung bình thời gian chuẩn bị nhóm theo số lượng pizza này

with CTE as 
    (select order_id, count(pizza_id) as pizza_number
    from pizza_runner.customer_orders
    group by order_id)
select pizza_number, avg(datediff(minute, order_date, pickup_time)) as avg_arrive_time
from CTE  
join pizza_runner.customer_orders as CO 
    on CTE.order_id = CO.order_id
join pizza_runner.runner_orders as RO   
    on CTE.order_id = RO.order_id
where cancellation = 'No'
group by pizza_number;

--Thời gian trung bình để chuẩn bị 1 pizza tương ứng với tổng số 1,2,3 pizza/order lần lượt là: 12, 9 và 10 phút
--> 2 pizza/order là số lượng pizza lý tưởng để đơn hàng được chuẩn bị nhanh nhất

--4. What was the average distance travelled for each customer?
--Mình dùng hàm avg cho cột distance, nhóm bởi customer_id, và làm tròn bằng hàm round với 1 chữ số thập phân sau dấu , để làm kết quả gọn hơn:

select customer_id, round(avg(distance), 1) as avg_customer_distance
from pizza_runner.customer_orders as CO 
join pizza_runner.runner_orders as RO 
    on CO.order_id = RO.order_id
where cancellation = 'No'
group by customer_id;

--5. What was the difference between the longest and shortest delivery times for all orders?
--Ta chỉ cần lấy max duration trừ đi min, và loại bỏ các trường hợp đơn hàng bị cancel

select max(duration) - min(duration) as delivery_time_diff
from pizza_runner.runner_orders
where cancellation = 'No';

--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

--Để tìm tốc độ trung bình của từng đơn hàng, mình lấy distance chia cho duration, 
--thường vận tốc sẽ tính theo m/s, hoặc km/h, nên mình sẽ chia duration cho 60 để đưa thời gian về giờ, 
--dùng cast để đưa data type duration về float thì mới thực hiện được phép chia nhé
--mình cũng dùng round để làm tròn kết quả cho gọn
--Đề yêu cầu tính vận tốc trung bình theo từng delivery, do mỗi order_id đã là unique nên ta không cần group by câu lệnh
--Cuối cùng mình sắp xếp kết quả theo runner_id, và vận tốc tăng dần để dễ theo dõi

select runner_id, order_id, distance, round((cast(duration as float)/60), 1) as duration, round((distance/(cast(duration as float)/60)), 1)  as avg_speed
from pizza_runner.runner_orders
where cancellation = 'No'
order by runner_id, (distance/(cast(duration as float)/60));

--Dựa vào kết quả này: vận tốc của runner 1 dao động từ 37,5 - 60 (km/h), runner 2 là 35,1 - 93,6 (km/h) và runner 3 là 40 km/h
--Mặc dù tốc độ giao hàng có thể thay đổi dựa trên tuyến đường, hay thời điểm giao hàng là giờ cao điểm hay thấp điểm
--Tuy nhiên khoảng chênh lệch vận tốc của runner 2 tương đối bất thường (đặc biệt có những đơn hàng có vận tốc lên tới hơn 90 km/h!)
--Danny tự mình thuê và điều hành Delivery Team (các runner), nên đây là một điều anh ấy sẽ phải khá lưu ý, 
--sẽ khá tệ nếu có người giao hàng đi quá nhanh và gây nguy hiểm cho bản thân và người khác

--7. What is the successful delivery percentage for each runner?
--Tỷ lệ giao hàng thành công là sẽ tính bằng số đơn hàng không bị cancel trên tổng số đơn hàng và nhóm bởi runner_id
--Nhớ là cast data type thành float thì mới thực hiện phép chia ra kết quả có số thập phân được nha:

select runner_id,  
    cast(count(case when cancellation = 'No' then 1 end) as float)/cast(count(*) as float) as successful_rate
from pizza_runner.runner_orders
group by runner_id;

--C. Ingredient Optimisation

--1. What are the standard ingredients for each pizza?

--Trước tiên mình đổi data type của toppings thành varchar để thực hiện các function với cột này:

alter table pizza_runner.pizza_recipes
alter column toppings varchar(50);

--Tương tự với cột topping_name ở bảng pizza_toppings:

alter table pizza_runner.pizza_toppings
alter column topping_name varchar(50);

--Ý tưởng cho câu này là mình sẽ truy vấn ra 1 bảng có pizza_id (optional), pizza_name và ingredient bao gồm các topping trong recipe của loại pizza đó
--Các topping này thật ra đã được liệt kê ngay trong bảng pizza_recipes, tuy nhiên để biết được tên của các topping đó thì mình phải join với bảng pizza_toppings
--Vì vậy ở đây mình cần phải tách các toppings trong bảng recipes ra thành các row để link từng topping đó với các topping_id, nhằm lấy được topping_name của chúng
--Ở đây mình sử dụng cross apply string_split như rất nhiều câu trên
--Khác biệt duy nhất là để cuối cùng các nguyên liệu của 2 loại pizza được liệt như 1 list thay vì các dùng, mình kết hợp chúng lại bằng hàm string_agg nhóm bởi loại pizza:

with CTE as
    (select PR.pizza_id, pizza_name, trim(value) AS topping
    from pizza_runner.pizza_recipes as PR 
    join pizza_runner.pizza_names as PN
        on PR.pizza_id = PN.pizza_id
    cross apply string_split (toppings, ','))
select pizza_id, pizza_name, string_agg (topping_name, ', ') as pizza_ingredients
from CTE
join pizza_runner.pizza_toppings as PT 
    on CTE.topping = PT.topping_id
group by pizza_id, pizza_name;

--2. What was the most commonly added extra?
--Các nguyên liệu được order tăng thêm được mô tả ở cột extras trong bảng customer_orders, mình vẫn dùng string_split để tách value của extras cho chuẩn 1NF
--Đếm số lần xuất hiện của các extras rồi sau đó link chúng với bảng toppings để lấy ra tên loại topping được add thêm nhiều nhất:

with CTE1 as 
    (select trim(value) as extra_ingredient
    from pizza_runner.customer_orders
    cross apply string_split(extras, ',')
    where extras <> '0'),
CTE2 as
    (select extra_ingredient, topping_name, count(*) as added_extra
    from CTE1
    join pizza_runner.pizza_toppings as PT 
        on extra_ingredient = PT.topping_id
    group by extra_ingredient, topping_name)
select extra_ingredient as added_most_topping, topping_name, added_extra as added_times
from CTE2 
where added_extra = (select max(added_extra) from CTE2);

--3. What was the most common exclusion?
--Tương tự yêu cầu trên:

with CTE1 as 
    (select trim(value) as exclude_ingredient
    from pizza_runner.customer_orders
    cross apply string_split(exclusions, ',')
    where exclusions <> '0'),
CTE2 as
    (select exclude_ingredient, topping_name, count(*) as exclusion_times
    from CTE1
    join pizza_runner.pizza_toppings as PT 
        on exclude_ingredient = PT.topping_id
    group by exclude_ingredient, topping_name)
select exclude_ingredient as excluded_most_topping, topping_name, exclusion_times as excluded_times
from CTE2 
where exclusion_times = (select max(exclusion_times) from CTE2);

--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
    --Meat Lovers
    --Meat Lovers - Exclude Beef
    --Meat Lovers - Extra Bacon
    --Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

with CTE as -- ở đây mình sử dụng row_number để đánh số các order_line, do có những order_line có thông tin giống hệt nhau, khi group sẽ dễ group nhầm
    (select row_number () over (order by order_id, pizza_id) as order_line, CO.*
    from pizza_runner.customer_orders as CO),
CTE1A as -- mình quyết định string_split exclusions và extra riêng rồi sau mới gộp lại, vì nếu split 2 cột 1 lúc thì value của 2 cột sẽ bị cross join với nhau
    (select CTE.*, trim(exclude.value) as exclude
    from CTE
    cross apply string_split (exclusions, ',') as exclude),
CTE1B as
    (select CTE.*, trim(extra.value) as extra
    from CTE
    cross apply string_split (extras, ',') as extra),
CTE2A as -- bước này là mình lấy tên của các loại topping
    (select order_line, order_id, pizza_id, exclusions, extras, PT.topping_name as exclude
    from CTE1A
    left join pizza_runner.pizza_toppings as PT
        on CTE1A.exclude = PT.topping_id),
CTE2B as
    (select order_line, order_id, pizza_id, exclusions, extras, PT.topping_name as extra
    from CTE1B
    left join pizza_runner.pizza_toppings as PT
        on CTE1B.extra = PT.topping_id),
CTE3A as -- sau đó gộp topping của từng pizza trong từng order line lại, group bằng order_line và kết hợp của cả 2 cột exclusion và extra để tránh nối thừa
    (select order_line, concat(exclusions, extras) as require, string_agg(exclude, ', ') as exclusions
    from CTE2A
    join pizza_runner.pizza_names as PN 
        on CTE2A.pizza_id = PN.pizza_id
    group by order_line, concat(exclusions, extras)),
CTE3B as
    (select order_line, concat(exclusions, extras) as require, string_agg(extra, ', ') as extras
    from CTE2B
    join pizza_runner.pizza_names as PN 
        on CTE2B.pizza_id = PN.pizza_id
    group by order_line, concat(exclusions, extras))
select order_id, customer_id, CTE.pizza_id, case 
        when CTE3A.exclusions is null and CTE3B.extras is null then pizza_name
        when CTE3A.exclusions is not null and CTE3B.extras is null then concat(pizza_name, ' - Exclude ', CTE3A.exclusions)
        when CTE3A.exclusions is null and CTE3B.extras is not null then concat(pizza_name, ' - Extra ', CTE3B.extras)
        when CTE3A.exclusions is not null and CTE3B.extras is not null then concat(pizza_name, ' - Exclude ', CTE3A.exclusions, ' - Extra ', CTE3B.extras)
    end as order_item
    , CTE.exclusions, CTE.extras, order_date -- cuối cùng là dùng case when để tạo tên từng bánh dựa trên thông tin về loại bánh và tên các topping
from CTE3A
join CTE3B 
    on CTE3A.order_line = CTE3B.order_line and CTE3A.require = CTE3B.require
join CTE
    on CTE3A.order_line = CTE.order_line
join pizza_runner.pizza_names as PN 
    on CTE.pizza_id = PN.pizza_id 
order by CTE3A.order_line;

--Đến đây mình nghĩ nếu tạo 1 số temporary thì code sẽ đỡ đáng sợ hơn...nhưng mình vẫn ưu tiên việc thể hiện logic câu lệnh để sau này xem lại, hoặc người khác đọc
--có thể sẽ thắc mắc "ủa cái bảng tạm này ở đâu??"

--5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
    --For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
--Ý tưởng gần giống như ở trên, nhưng mình sẽ tạo thêm CTE để lấy ra ingredient list từ bảng topping
--Và quan trọng nhất trong câu này: chia case để tạo ra các nguyên liệu 2x (được extra) và loại đi các nguyên liệu bị exclude (exclusion)

with CTE as 
    (select row_number () over (order by order_id, pizza_id) as order_line, CO.*
    from pizza_runner.customer_orders as CO),
CTE1A as -- Mình dùng 2 CTE1A và CTE1B để đưa danh sách ingredient chính của 2 loại pizza vào trong truy vấn chính
    (select pizza_id, trim(value) as ingredient
    from pizza_runner.pizza_recipes
    cross apply string_split(toppings, ',') as ingredient),
CTE1B as
    (select pizza_id, topping_id, topping_name as ingredient
    from CTE1A
    join pizza_runner.pizza_toppings as PT 
        on CTE1A.ingredient = PT.topping_id),
CTE2 as
    (select order_line, order_id, customer_id, CTE.pizza_id, pizza_name, (case 
            when charindex(cast(topping_id as varchar(max)), extras) > 0 then concat ('2x', ingredient)
            when charindex(cast(topping_id as varchar(max)), exclusions) > 0 then null
            else ingredient
            --Ở đoạn này, ban đầu mình sử dụng topping_id like % extras %/% exclusions % nhưng kết quả trả về không chính xác
            --Do đó mình quyết định sử dụng charindex để scan các topping_id này trong từng extras/exclusions
            --Mọi người cũng có thể sử dụng toán tử 'in' nếu có CTE đã break 2 cột extra và exclusion
        end) 
        as ingredient
        , CTE.order_date 
    from CTE
    join pizza_runner.pizza_names as PN 
        on CTE.pizza_id = PN.pizza_id 
    join CTE1B
        on CTE.pizza_id = CTE1B.pizza_id)
select 
    order_line, 
    order_id, 
    customer_id, 
    pizza_id, 
    concat(pizza_name, ': ', string_agg(ingredient, ', ' ) within group (order by ingredient asc)) as ingredient_list 
                                                        -- dùng within group để sắp xếp các item được tổng hợp trong hàm string_agg
from CTE2
group by order_line, order_id, customer_id, pizza_id, pizza_name
order by order_line;

--6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
--Câu này mình thấy đơn giản hơn 2 câu trên ở chỗ không cần quan tâm tới/nhóm theo từng order line một
--Vấn đề duy nhất là chia case when cho chuẩn extra/exclusion để tính đúng số lần nguyên liệu được sử dụng

with CTE1 as
    (select pizza_id, trim(value) as ingredient_id
    from pizza_runner.pizza_recipes
    cross apply string_split(toppings, ',')),
CTE2 as
    (select 
        CO.order_id,
        PT.topping_name as ingredient,
        case
            when charindex(cast(PT.topping_id as varchar), CO.extras) > 0 then 2 -- Nếu là nguyên liệu bổ sung, thêm 2
            when charindex(cast(PT.topping_id as varchar), CO.exclusions) > 0 then 0 -- Nếu là nguyên liệu bị loại bỏ, thêm 0
            else 1 -- Không có nguyên liệu bổ sung hoặc loại bỏ, thêm 1
        end as times_used
    from pizza_runner.customer_orders as CO
    join CTE1
        on CO.pizza_id = CTE1.pizza_id
    join pizza_runner.pizza_toppings as PT
        on topping_id = ingredient_id)
select ingredient, sum(times_used) as times_used 
from 
  CTE2
group by 
  ingredient
order by
  times_used desc;

--D. Pricing and Ratings

--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes  
    --how much money has Pizza Runner made so far if there are no delivery fees?

with CTE as
    (select case 
            when pizza_name = 'Meat Lovers' then 12
            when pizza_name = 'Vegetarian' then 10
        end as Amount
    from pizza_runner.customer_orders as CO
    join pizza_runner.pizza_names as PN
        on CO.pizza_id = PN.pizza_id
    join pizza_runner.runner_orders as RO  
        on CO.order_id = RO.order_id
    where cancellation = 'No')
select sum(Amount) as Revenue
from CTE;

--2. What if there was an additional $1 charge for any pizza extras?
    --Add cheese is $1 extra

with CTE1 as 
    (select row_number() over (order by order_id, pizza_id) as order_line, *
    from pizza_runner.customer_orders),
CTE2 as  
    (select order_line, trim(value) as extra_ingredient
    from CTE1
    cross apply string_split(extras, ',')),
CTE3 as 
    (select order_line, count(case when extra_ingredient <> 0 then 1 end) as ingredient_count
    from CTE2
    group by order_line),
CTE4 as
    (select CTE1.*, case
            when pizza_name = 'Meat Lovers' then (12 + ingredient_count*1)
            when pizza_name = 'Vegetarian' then (10 + ingredient_count*1)
        end as Amount
    from CTE1 
    join CTE3
        on CTE1.order_line = CTE3.order_line
    join pizza_runner.pizza_names as PN
        on CTE1.pizza_id = PN.pizza_id
    join pizza_runner.runner_orders as RO  
        on CTE1.order_id = RO.order_id
    where cancellation = 'No')
select sum(Amount) as Revenue
from CTE4;

--3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
    --how would you design an additional table for this new dataset
    --generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

--Với bảng ratings này: mình sẽ tạo 2 column: order_id và rating

create table pizza_runner.ratings (
    order_id int,
    rating int
)

--Giờ mình sẽ nhập rating ngẫu nhiên cho các đơn hàng thành công (tức loại trừ 2 đơn hàng 6 và 9)

insert into pizza_runner.ratings
values 
  (1,3),
  (2,5),
  (3,3),
  (4,1),
  (5,5),
  (7,3),
  (8,4),
  (10,3);

--4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
    --customer_id
    --order_id
    --runner_id
    --rating
    --order_time
    --pickup_time
    --Time between order and pickup
    --Delivery duration
    --Average speed
    --Total number of pizzas

select 
    customer_id, 
    CO.order_id, 
    runner_id, 
    rating, 
    order_date as order_time, 
    pickup_time, 
    datediff(minute, order_date, pickup_time) as arriving_time, 
    duration, 
    round((distance/(cast(duration as float)/60)), 1)  as avg_speed,
    count(*) as pizza_number
from pizza_runner.customer_orders as CO 
join pizza_runner.runner_orders as RO   
    on CO.order_id = RO.order_id
join pizza_runner.ratings as R 
    on CO.order_id = R.order_id
where cancellation = 'No'
group by customer_id, 
    CO.order_id, 
    runner_id, 
    rating, 
    order_date, 
    pickup_time, 
    datediff(minute, order_date, pickup_time), 
    duration, 
    round((distance/(cast(duration as float)/60)), 1)
order by order_id;

--5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
    --how much money does Pizza Runner have left over after these deliveries?

--Mình sẽ tính tổng số tiền Pizza Runner thu được từ tất cả đơn hàng như ở câu 1, sau đó trừ đi chi phí cho các runner - tính bằng đơn giá/km nhân với distance
--Ở đây mình sẽ tạo 2 CTE: 1 CTE tính revenue, 1 CTE tính chi phí cho runner thay vì tính gộp (do doanh thu đang tính trên từng pizza, còn tiền ship lại tính trên từng đơn hàng)

with CTE1A as
    (select case 
            when pizza_name = 'Meat Lovers' then 12
            when pizza_name = 'Vegetarian' then 10
        end as amount
    from pizza_runner.customer_orders as CO
    join pizza_runner.pizza_names as PN
        on CO.pizza_id = PN.pizza_id
    join pizza_runner.runner_orders as RO   
        on CO.order_id = RO.order_id
    where cancellation = 'No'),
CTE1B as 
    (select 0.3*distance as runner_cost
    from pizza_runner.runner_orders),
CTE2A as    
    (select sum(amount) as revenue
    from CTE1A),
CTE2B as 
    (select sum(runner_cost) as runner_cost
    from CTE1B)
select (revenue - runner_cost) as left_over
from CTE2A, CTE2B;

--E. Bonus Questions

--If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
--Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

--Nếu Danny muốn thêm 1 loại pizza mới vào menu, anh ấy cần bắt đầu bổ sung thông tin vào dataset
--Bắt đầu từ bảng pizza_names, sau đó là pizza_recipes

insert into pizza_runner.pizza_names
values (3, ' Supreme')

insert into pizza_runner.pizza_recipes
values (
    3, 
    (select string_agg (topping_id, ', ') as toppings
    from pizza_runner.pizza_toppings)
);