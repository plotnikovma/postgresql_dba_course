-- развернем ВМ postgres в YC

yc vpc network create --name otus-net --description "otus-net" && \
yc vpc subnet create --name otus-subnet --range 192.168.0.0/24 --network-name otus-net --description "otus-subnet" && \
yc compute instance create --name otus-vm --hostname otus-vm --cores 2 --memory 4 --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key ~/.ssh/yc_key.pub && vm_ip_address=$(yc compute instance show --name otus-vm | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 

sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14 && wget https://edu.postgrespro.ru/demo_small.zip && sudo apt install unzip && unzip demo_small.zip && sudo -u postgres psql -d postgres -f /home/yc-user/demo_small.sql -c 'alter database demo set search_path to bookings' && wget https://www.postgresqltutorial.com/wp-content/uploads/2019/05/dvdrental.zip && unzip dvdrental.zip && sudo -u postgres psql -c 'create database dvdrental' && sudo -u postgres pg_restore -d dvdrental dvdrental.tar

ssh -i ~/.ssh/yc_key yc-user@$vm_ip_address 


-- посмотрим, что кластер стартовал

pg_lsclusters

sudo -u postgres psql


-- database
-- system catalog
SELECT oid, datname, datistemplate, datallowconn FROM pg_database;
-- size
SELECT pg_size_pretty(pg_database_size('postgres'));


-- schema
\dn
-- current schema
SELECT current_schema();
-- view table
\d pg_database
-- list of ALL namespaces
SELECT * FROM pg_namespace;

-- seach path
SHOW search_path;
-- SET search_path to .. - в рамках сессии
-- параметр можно установить и на уровне отдельной базы данных:
-- ALTER DATABASE otus SET search_path = public, special;
-- в рамках кластера в файле postgresql.conf

\dt


-- интересное поведение и search_path
\d pg_database
CREATE TABLE pg_database (i int);
-- все равно видим pg_catalog.pg_database
\d pg_database
-- чтобы получить доступ к толко что созданной таблице используем указание схемы
\d public.pg_database
SELECT * FROM pg_database limit 1;

-- в 1 схеме или разных?
CREATE TABLE t1(i int);
CREATE SCHEMA postgres;
CREATE TABLE t2(i int);

CREATE TABLE t1(i int);
\dt
\dt public.o
SET search_path TO public, "$user";
\dt

SET search_path TO public, "$user", pg_catalog;
\dt

create temp table t1(i int);
\dt

SET search_path TO public, "$user", pg_catalog, pg_temp;
\dt


-- можем переносить таблицу между схемами - при этом меняется только запись в pg_class, физически данные на месте
ALTER TABLE t2 SET SCHEMA public;


-- relations
SELECT * FROM pg_class \gx

CREATE DATABASE logical;
\c logical
CREATE TABLE testL(i int);
SELECT 'testL'::regclass::oid;
-- look on filesystem
SELECT oid, datname FROM pg_database WHERE datname='logical';

sudo su
cd /var/lib/postgresql/14/main/base/17072
ls -l | grep 16408
-- adding some data
INSERT INTO testL VALUES (1),(3),(5);
-- look on filesystem
ls -l | grep 16406  
exit

sudo -u postgres psql
-- create index on new table
CREATE index indexL on testL (i);
SELECT 'indexL'::regclass::oid;
-- look on filesystem
ls -l | grep 17073

-- мы также можем посмотреть, что происходит внутри вызова системных команд
\set ECHO_HIDDEN on
\l
\d
\set ECHO_HIDDEN off

-- view
-- materialized view
create table sklad (id serial PRIMARY KEY, name text, kolvo int, price numeric(17,2));
create table sales(id serial PRIMARY KEY, kolvo int, summa numeric(17,2), fk_skladID int references sklad(id), salesDate date);

insert into sklad (id, name, price) values (1, 'Сливы', 100), (2, 'Яблоки', 120);
insert into sales(fk_skladID, kolvo) values (1, 10), (2, 5);

create view v_sales as select s.*, sk.name from sales as s join sklad sk on s.fk_skladID = sk.id;

select * from v_sales;

insert into sales(fk_skladID, kolvo) values (1, 5);

select * from v_sales;
-- материлизованное представление работает быстрее обычного но его надо обновлять refresh
create materialized view ms as select s.*, sk.name from sales as s join sklad sk on s.fk_skladID = sk.id;

select * from ms;

insert into sales(fk_skladID, kolvo) values (1, 5);

select * from ms;

-- https://postgrespro.ru/docs/postgresql/14/sql-refreshmaterializedview
refresh materialized view ms;

select * from ms;

refresh materialized view CONCURRENTLY ms WITH DATA;

CREATE UNIQUE INDEX ui ON sklad(id);
refresh materialized view CONCURRENTLY ms WITH DATA;
DROP INDEX ui;

-- index unique on MAT VIEW!!!
CREATE UNIQUE INDEX ui ON ms(id);
refresh materialized view CONCURRENTLY ms WITH DATA;


-- foreign table
CREATE DATABASE testfdw;
\c testfdw
CREATE TABLE testf(i int);
INSERT INTO testf values (111), (222);
-- pass 123
\password

\c logical
create extension postgres_fdw;
CREATE SERVER myserver FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'localhost', dbname 'testfdw', port '5432');
CREATE USER MAPPING FOR postgres SERVER myserver OPTIONS (user 'postgres', password '123');
CREATE FOREIGN TABLE testf(i int) server myserver;
select * from testf;

-- также возможны джойны и тд

-- another extension dblink





-- Users

SELECT usename, usesuper FROM pg_catalog.pg_user;
\du

CREATE USER test;
SELECT * FROM pg_catalog.pg_user;

-- попробуем законнектиться
\c - test

ALTER USER test LOGIN;
\c - test

-- почему не подключились?



-- peer аутентификация через unix socket, а в unix нет пользователя тест
-- включим md5
\password test
или
ALTER USER test PASSWORD 'otus$123';

sudo -u postgres psql -U test -h 127.0.0.1 -W -d postgres

exit

sudo -u postgres psql
CREATE TABLE testa(i int);
INSERT INTO testa values (333), (444);

CREATE TABLE testa2(i int);
INSERT INTO testa2 values (555), (6666);

-- выдадим группе PUBLIC права на эту таблицу
GRANT SELECT ON testa TO PUBLIC;
GRANT SELECT, UPDATE, INSERT ON testa TO test;
-- GRANT SELECT (col1), UPDATE (col1) ON testa TO test;

\dp testa
ALTER TABLE testa SET SCHEMA public;
ALTER TABLE testa2 SET SCHEMA public;

exit
sudo -u postgres psql -U test -h 127.0.0.1 -W -d postgres
\dt
select * from sklad;
select * from testa;
insert into testa values(777);

-- попробуем нового юзера создать из под test, postgres
CREATE USER test2 WITH PASSWORD '123' NOLOGIN;
sudo -u postgres psql -U test2 -h 127.0.0.1 -W -d postgres



-- удалим наш проект
gcloud compute instances delete postgres



https://www.postgresql.org/docs/14/auth-ldap.html
https://postgrespro.ru/docs/postgresql/14/gssapi-auth

