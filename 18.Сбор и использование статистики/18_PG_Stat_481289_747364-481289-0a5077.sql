-- Создаем сетевую инфраструктуру для VM:
yc vpc network create --name otus-net --description "otus-net" && \
yc vpc subnet create --name otus-subnet --range 192.168.0.0/24 --network-name otus-net --description "otus-subnet" && \
yc compute instance create --name otus-vm --hostname otus-vm --cores 2 --memory 4 --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key ~/.ssh/yc_key.pub 

vm_ip_address=$(yc compute instance show --name otus-vm | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 

sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14 

pg_lsclusters

sudo nano /etc/postgresql/14/main/postgresql.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf

sudo -u postgres psql
alter user postgres password 'postgres';

sudo pg_ctlcluster 14 main restart

wget https://edu.postgrespro.ru/demo_small.zip && sudo apt install unzip && unzip demo_small.zip && sudo -u postgres psql -d postgres -f /home/yc-user/demo_small.sql -c 'alter database demo set search_path to bookings' 



show track_activities;
show track_counts;
show track_functions;
show track_io_timing;

select datname
     , numbackends
     , xact_commit
     , xact_rollback
     , blks_read
     , blks_hit
     , tup_returned
     , tup_fetched
     , tup_inserted
     , tup_updated
     , tup_deleted
     , stats_reset
from pg_stat_database
where datname = 'demo';

select *
from pg_stat_database
where datname = 'demo';


select distinct(relkind) from pg_class;

select * from pg_class where relname = 'bookings'; --65664

explain analyze
select * from flights; --Seq Scan on flights  (cost=0.00..1448.64 rows=65664 width=63)

select relkind, count(*)
from pg_class
group by relkind;


select * from pg_stats where tablename = 'bookings';

create table test1 (id int); 

insert into test1 select * from generate_series(1, 10000);

analyze test1;

select *
from pg_stats
where tablename = 'test1';

select *
from pg_stats
where tablename = 'flights';

select sum(case when actual_arrival is null then 1 else null end)::numeric / count(*)
from bookings.flights; -- 0.49533528577035717521

select count(distinct flight_no)
from bookings.flights;

select most_common_vals,array_length(most_common_vals,1),n_distinct
from pg_stats
where tablename= 'flights';

-- Колонка correlation в представлении pg_stat показывает коэффициент корреляции между столбцами таблицы. Этот коэффициент может помочь в оптимизации запросов, так как он указывает на степень зависимости между столбцами. Если коэффициент корреляции близок к 1 или -1, это может означать, что столбцы имеют сильную положительную или отрицательную корреляцию, и можно использовать эту информацию для выбора правильных индексов или оптимизации запросов.


--Посмотрим корелляцию
create table test1 as
    select *
from generate_series(1, 10000);
analyse test1;

select correlation
from pg_stats
where tablename = 'test1';

create table test2 as
select *
from test1
order by random();
analyse test2;

select correlation
from pg_stats
where tablename = 'test2';


drop table test3;

create table test3 as
select *
from test1
order by generate_series(1, 1000) desc;

analyse test3;

select correlation
from pg_stats
where tablename = 'test3';


drop table test4;  -- По json статистика не ведется
create table test4 as
    select '{"some_val" : "value"}'::jsonb as c1;
analyze test4;

select *
from pg_stats
where tablename = 'test4';


create table test5 as
select (array[2, 4, 5]);
analyse test5;

select *
from pg_stats
where tablename = 'test5';
select * from test5;


select count(*)
from bookings.flights
where flight_no = 'PG0007' and departure_airport = 'VKO'; -- 61

explain -- 2
select *
from bookings.flights
where flight_no = 'PG0007' and departure_airport = 'VKO';

create statistics flights_multi(dependencies) on flight_no, departure_airport from bookings.flights;
select * from pg_statistic_ext;
analyze bookings.flights;
drop statistics flights_multi;

explain -- 44
select *
from bookings.flights
where flight_no = 'PG0007' and departure_airport = 'VKO';

select count(*)
from
(
    select distinct departure_airport, arrival_airport
    from bookings.flights
) s1; -- 618

explain
select distinct departure_airport, arrival_airport
from bookings.flights; -- 3312

create statistics flights_multi_dist(ndistinct) on departure_airport, arrival_airport from bookings.flights;
select * from pg_statistic_ext;
analyze bookings.flights;
drop statistics flights_multi_dist;

explain -- 618
select distinct departure_airport, arrival_airport
from bookings.flights;

explain -- 618
select departure_airport, arrival_airport
from bookings.flights
group by departure_airport, arrival_airport;


-- Приемчик оптимизации

-- Постгрес ничего не знает о функции, которую мы применяем.
-- Поэтому, по умолчанию кол-во строк будет рассчитываться из общего количества * 0,005
-- Общее количество 16235 => 16235 * 0,005 = 1074,335
select count(*)
from bookings.flights
where extract(month from scheduled_departure) = 6;


create or replace function func1() returns integer as $$
declare 
a int8;
begin
	select count(*) into a
from
(
    select distinct departure_airport, arrival_airport
    from bookings.flights
) s1;
return a;
end;
$$ language plpgsql;

select func1();



explain
select *
from bookings.flights
where extract(month from scheduled_departure) = 6;

create function get_month(t timestamptz) returns integer as $$
    select extract(month from t)::integer
    $$ immutable language sql;

create index on bookings.flights(get_month(scheduled_departure));
analyse bookings.flights;

explain
select *
from bookings.flights
where get_month(scheduled_departure) = 6;


select *
from pg_stat_activity;

select * from generate_series(1, 10000000000);


select * from pg_stat_user_tables where relname = 'flights';



vacuum analyze test6;

select * from test6 limit 100;

delete from test6 where id between 1 and 1000;

select * from bookings.flights;

delete from bookings.flights where flight_id between 1 and 1000;

create table test6 (id int);

insert into test6 select * from generate_series(1, 10000);
analyze test6;

delete from flights where flight_id=5;

explain analyze
select count(*) from bookings.flights; -- seq_tup_read

select * from pg_stat_user_tables where relname = 'flights'; -- 132684 -> 165805


create index idx_test6 on test6(id);

explain
select * from test6 where id = 9999;

analyze test6;

select *
from pg_stat_user_indexes
where relname = 'flights';  66168,58



show enable_indexscan;

--set enable_indexscan = 'on';
explain analyse
select flight_id from bookings.flights where flight_id < 1000;

--неиспользуемые индексы
select s.schemaname,
       s.relname as tablename,
       s.indexrelname as indexname,
       pg_size_pretty(pg_relation_size(s.indexrelid)) as index_size,
       s.idx_scan
from pg_catalog.pg_stat_user_indexes s
   join pg_catalog.pg_index i on s.indexrelid = i.indexrelid
where s.idx_scan < 10      -- has never been scanned
  and 0 <> all (i.indkey)  -- no index column is an expression
  and not i.indisunique   -- is not a unique index
  and not exists          -- does not enforce a constraint
         (select 1 from pg_catalog.pg_constraint c
          where c.conindid = s.indexrelid)
order by pg_relation_size(s.indexrelid) desc;

select * from pg_catalog.pg_stat_user_indexes;


show shared_preload_libraries;

create extension pg_stat_statements;

set shared_preload_libraries = 'pg_stat_statements';


select * from pg_stat_statements
where query like '%bookings.bookings%';

select *
from bookings.bookings
where book_ref = '000012';
