-- создадим расширение для просмотра кеша
create extension pg_buffercache; 
select setting, unit from pg_settings where name = 'shared_buffers'; 

-- уменьшим количество буферов для наблюдения
alter system set shared_buffers = 300;


create table if not exists test(i int); -- drop table if exists test;

insert into test(i) values (1); 

-- сгенерируем значения
insert into test select s.id from generate_series(1, 10000) as s(id); 
select * from test;

select * from pg_buffercache;

create or replace view pg_buffercache_v as
select bufferid, (select c.relname from pg_class c where  pg_relation_filenode(c.oid) = b.relfilenode) relname,
case relforknumber
	when 0 then 'main'
	when 1 then 'fsm'
	when 2 then 'vm'
end relfork,
relblocknumber,
isdirty,
usagecount
from pg_buffercache b
where b.reldatabase in (0, (select oid from pg_database where datname = current_database()))
and b.usagecount is not null;

select * from pg_buffercache_v where relname = 'test';

select 
	c.relnamespace::regnamespace as schema, 
	c.relname, 
	count(*) as buffers, 
	pg_size_pretty(count(*) * current_setting('block_size')::int) as cache_size
from pg_buffercache b 
inner join pg_class c on b.relfilenode = pg_relation_filenode(c.oid) 
where c.relname = 'test'
group by c.relnamespace, c.relname;



select * from test limit 10;

update test set i = 2 where i = 1;


-- увидим грязную страницу
select * from pg_buffercache_v where relname = 'test';


-- даст пищу для размышлений над использованием кеша -- usagecount > 3
select c.relname,
  count(*) blocks,
  round( 100.0 * 8192 * count(*) / pg_table_size(c.oid) ) "% of rel",
  round( 100.0 * 8192 * count(*) filter (where b.usagecount > 3) / pg_table_size(c.oid) ) "% hot"
from pg_buffercache b
  join pg_class c on pg_relation_filenode(c.oid) = b.relfilenode
where  b.reldatabase in (
         0, (select oid from pg_database where datname = current_database())
       )
and    b.usagecount is not null
group by c.relname, c.oid
order by 2 desc
limit 10;

-- сгенерируем значения с текстовыми полями - чтобы занять больше страниц
create table if not exists test_text(t text); -- drop table if exists test_text;
insert into test_text select 'строка '||s.id from generate_series(1, 500) as s(id); 
select * from test_text limit 10;
select * from test_text;
select * from pg_buffercache_v where relname = 'test_text';

-- интересный эффект
vacuum test_text;


-- посмотрим на прогрев кеша
-- рестартуем кластер для очистки буферного кеша
-- sudo pg_ctlcluster 14 main restart

select * from pg_buffercache_v where relname = 'test_text';
create extension pg_prewarm;
select pg_prewarm('test_text');
select * from pg_buffercache_v where relname = 'test_text';


create extension pageinspect; -- содержит набор функций/представлений, обеспечивающих нам доступ на нижний уровень к страничкам базы данных (superuser!)

select * from pg_ls_waldir() limit 10; -- 000000010000000000000001 -- что лежит в директории pg_wall


begin transaction;
-- текущая позиция lsn
select pg_current_wal_insert_lsn(); -- 0/18C5598 / 0/18C7978 / 0/183F3A0 (должно быть больше)
-- посмотрим какой у нас wal file
select pg_walfile_name('0/18C5598'); -- 000000010000000000000001
update test_text set t = '10' where t = 'строка 1';
select pg_current_wal_lsn(); -- 0/18C7978
-- после update номер lsn изменился
select lsn from page_header(get_raw_page('test_text',0)); -- получим заголовок нашей страницы / 0/18C7940
-- размер журнальных записей между ними (в байтах):
select '0/18C7978'::pg_lsn - '0/18C5598'::pg_lsn as bytes; -- 9184
commit transaction;

insert into test_text (t) values ('сбой');
-- sudo pg_ctlcluster 14 main stop -m immediate (smart, fast)
-- sudo /usr/lib/postgresql/14/bin/pg_controldata /var/lib/postgresql/14/main/
-- sudo pg_ctlcluster 14 main start

select * from test_text where t = 'сбой';

-- Посмотреть что за запись:
select * from pg_ls_waldir() limit 10;
-- sudo /usr/lib/postgresql/14/bin/pg_waldump -p /var/lib/postgresql/14/main/pg_wal -s 0/18C5598 -e 0/18C7978 000000010000000000000001


alter system set checkpoint_timeout = '30s';


create table test_pg(i int);
-- сгенерируем значения
insert into test_pg select s.id from generate_series(1,10000) as s(id); 
select * from test_pg limit 10;

checkpoint;

select * from pg_buffercache_v where relname='test_pg';

checkpoint;

select * from pg_stat_bgwriter;

show fsync;
show wal_sync_method; 
show data_checksums;
