with rank_users as
(
select city
      ,user_id
      ,num_orders
      ,rnk
from
(  select  city
          ,user_id
          ,count(order_id) as num_orders
          ,rank() over (partition by city order by count(order_id) desc) as rnk
  from    `efood2022-372214.main_assessment.orders`
  group by 1,2
)
where rnk <= 10
)

,orders_per_city as
(
select    city
         ,count(order_id) as total
from     `efood2022-372214.main_assessment.orders`
group by 1
)

select    a.city
         ,user_id
         ,round((num_orders/total)*100,2) as percentage
from      rank_users      as a
left join orders_per_city as b
on        a.city = b.city