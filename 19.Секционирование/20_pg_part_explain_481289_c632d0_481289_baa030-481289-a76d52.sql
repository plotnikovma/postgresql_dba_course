set jit = 'off';
show jit;

explain analyze
select sum(order_total) from no_part.orders where order_date between '2020-01-01'::date and '2020-04-01'::date - 1;

-- Execution Time: 955.505 ms

explain analyze
select sum(order_total) from by_range.orders where order_date between '2020-01-01'::date and '2020-04-01'::date - 1;
-- Execution Time: 71.187 ms


explain analyze
select sum(order_total) from no_part.orders where order_date between '2020-01-01'::date and '2020-01-31'::date - 1;
-- Execution Time: 2136.925 ms

explain analyze
select sum(order_total) from by_range.orders where order_date between '2020-01-01'::date and '2020-01-31'::date - 1;
-- Execution Time: 97.560 ms

explain analyze
select sum(order_total) from by_range.orders where client = 'Иван Васильевич';
-- Execution Time: 7619.229 ms

explain analyze
select sum(order_total) from no_part.orders where client = 'Иван Васильевич';


explain analyze
select sum(order_total) from by_list.orders where client = 'Иван Васильевич';
-- Execution Time: 259.237 ms

explain analyze
select sum(order_total) from by_list.orders where client = 'Иван Васильевич' and order_id in (select * from generate_series(1, 1000));
-- Execution Time: 3.176 ms



insert into by_list.orders (client, order_date, order_total) values ('John Connor', '2012-12-12', 777);

create table by_list.orders_default partition of by_list.orders default;


explain analyze
select * from by_list.orders_default;


explain analyze
select sum(order_total) from by_list.orders where client = 'John Connor';
-- Execution Time: 190.309 ms


select * from by_list.orders_4 limit 100; -- Пётр Алексеевич

create table by_list.orders_4_new (like by_list.orders_4 including all);

insert into by_list.orders_4_new (order_id, client, order_date, order_total) 
select s + 20000000, 'Пётр Алексеевич', '2025-01-10', random() * 25000 + 10. from generate_series(1, 1000000) s;

select * from by_list.orders_4_new limit 100;


alter table by_list.orders detach partition by_list.orders_4;

alter table by_list.orders attach partition by_list.orders_4_new for values in ('Пётр Алексеевич'); 

explain analyze
select * from by_list.orders where client = 'Пётр Алексеевич';



/*
Прежде чем выполнить ATTACH PARTITION, рекомендуется создать ограничение CHECK в присоединяемой таблице, соответствующее ожидаемому ограничению секции.Благодаря этому система сможет обойтись без сканирования, необходимого для проверки неявного ограничения секции. Без этого ограничения CHECK нужно будет просканировать и убедиться в выполнении ограничения секции, удерживая блокировку ACCESS EXCLUSIVE в этой секции. После выполнения команды ATTACH PARTITION рекомендуется удалить ограничение CHECK, поскольку оно больше не нужно. Если присоединяемая таблица также является секционированной таблицей, то каждая из её секций будет рекурсивно блокироваться и сканироваться до тех пор, пока не встретиться подходящее ограничение CHECK или не будут достигнуты конечные разделы. 
*/


create table by_list.orders_8 partition of by_list.orders for values in ('John Connor'); -- Ошибка

create table by_list.orders_8 (like by_list.orders);

insert into by_list.orders_8 select * from by_list.orders_default;


alter table by_list.orders attach partition by_list.orders_8 for values in ('John Connor');

explain analyze
select * from by_list.orders where client = 'John Connor';


-- Индексы
create index concurrently ix00 on by_list.orders using btree (order_date); -- Ошибка, без concurrently блокировка

create index ix00 on only by_list.orders using btree (order_date);
-- на головной не создается, а на секции создать можно

create index concurrently ix01 on by_list.orders_0 using btree (order_date);




