-- table with all cities with number of breakfast orders
drop table if exists `efood2022-372214.main_assessment.city_order_breakf`;
create table if not exists `efood2022-372214.main_assessment.city_order_breakf` as

select   city
        ,count(order_id) as num_breakfast_orders
from    `efood2022-372214.main_assessment.orders`
where    cuisine = 'Breakfast'
group by city
;

-- table with Basket & Frequency metrics for every city that exceeds 1000 orders for breakfast & total efood
drop table if exists `efood2022-372214.main_assessment.basket_freq_data`;
create table if not exists `efood2022-372214.main_assessment.basket_freq_data` as

select     city                                                                                                                         as city
          ,sum(case when cuisine = 'Breakfast' then amount else 0 end) / count(case when cuisine = 'Breakfast' then order_id end)       as breakfast_basket
          ,sum(amount) / count(order_id)                                                                                                as total_basket
          ,count(case when cuisine = 'Breakfast' then order_id end) / count(distinct(case when cuisine = 'Breakfast' then user_id end)) as breakfast_freq
          ,count(order_id) / count(distinct user_id)                                                                                    as total_freq
from      `efood2022-372214.main_assessment.orders`
group by  city
having    count(order_id) > 1000;

-- table with total users that exceed 3 orders
drop table if exists `efood2022-372214.main_assessment.total_users_3freq`;
create table if not exists `efood2022-372214.main_assessment.total_users_3freq` as

with total_users_3freq as
(
select city
      ,count(user_id) as users_freq3
from (
      select    city
               ,user_id
               ,count(order_id) as num_orders
      from     `efood2022-372214.main_assessment.orders`
      group by  1,2
      having    num_orders > 3
      )
group by city)

,total_users as
(
select    city
         ,count(distinct(user_id)) as total_users_freq3
from      `efood2022-372214.main_assessment.orders`
group by  city
having    count(order_id) > 1000
)

select    a.city
         ,b.users_freq3/a.total_users_freq3 as total_users_3freq
from      total_users as a
left join total_users_3freq as b
on        a.city = b.city
;

-- table with breakfast users that exceed 3 orders
drop table if exists `efood2022-372214.main_assessment.breakf_users_3freq`;
create table if not exists `efood2022-372214.main_assessment.breakf_users_3freq` as

with breakf_users_3freq as
(
select city
      ,count(user_id) as breakf_users_3
from (
      select    city
               ,user_id
               ,count(case when cuisine = 'Breakfast' then order_id end) as num_orders
      from     `efood2022-372214.main_assessment.orders`
      group by  1,2
      having    num_orders > 3
      )
group by city)

,breakf_total_users as
(
select    city
         ,count(distinct(case when cuisine = 'Breakfast' then user_id end)) as breakf_total_users
from      `efood2022-372214.main_assessment.orders`
group by  city
having    count(order_id) > 1000
)

select    a.city
         ,b.breakf_users_3/a.breakf_total_users as breakf_users_3freq
from      breakf_total_users as a
left join breakf_users_3freq as b
on        a.city = b.city
;

select      a.city
           ,breakfast_basket
           ,total_basket
           ,breakfast_freq
           ,total_freq
           ,breakf_users_3freq
           ,total_users_3freq
from       `efood2022-372214.main_assessment.city_order_breakf`  as a
left join  `efood2022-372214.main_assessment.basket_freq_data`   as b
on          a.city = b.city
inner join `efood2022-372214.main_assessment.breakf_users_3freq` as c
on          a.city = c.city
inner join `efood2022-372214.main_assessment.total_users_3freq`  as d
on          a.city = d.city
order by    num_breakfast_orders desc
limit       5


