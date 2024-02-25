\\-- ЭТО не SQL-команды, выполняем в терминале linux или командной строке Windows
--          psql -dpostgres
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- #1       Базы данных
-- просмотр баз данных кластера:
SELECT * FROM pg_database;
-- Или команды psql \l и \l+

-- только "интересные" столбцы
SELECT  datname, encoding, pg_encoding_to_char(encoding),
        dattablespace, datistemplate, datallowconn
FROM pg_database;

-- #1.1
-- Создание базы данных с атрибутами по умолчанию
-- в данном случае будет создана БД с параметрами по-умолчанию, за основу берется дефолтный шаблон template1
create database <db_name>;
-- или задать явно
create database <db_name> with is_template = 1;

----------------------------------------------------------------------------------------------------
-- #1.2
-- изменение БД
ALTER DATABASE <db_name> RENAME TO <new_db_name>;
ALTER DATABASE <db_name> OWNER TO { новый_владелец | CURRENT_USER | SESSION_USER };
ALTER DATABASE <db_name> SET TABLESPACE <новое_табличное_пространство>;
ALTER DATABASE <db_name> SET <параметр_конфигурации> { TO | = } { значение | DEFAULT };
ALTER DATABASE <db_name> SET <параметр_конфигурации> FROM CURRENT;
ALTER DATABASE <db_name> RESET <параметр_конфигурации>;
-- сброс всех параметров до значений шаблона, на основе которого сделана БД
ALTER DATABASE <db_name> RESET ALL;

-- Переключение на созданную БД: 
-- \c otus_ddl

----------------------------------------------------------------------------------------------------
-- #2 Табличные пространства - позволяет раздельно хранить таблицы, к примеру часть на быстрых дисках, часть на медленныхёс
/* 
   ЭТО не SQL-команды, выполняем в терминале linux или командной строке Windows
            mkdir /home/master/pg_ext_data
		    или
			mkdir /home/student/pg_ext_data
			
            sudo chown postgres:postgres /home/master/pg_ext_data
			или
sudo chown postgres:postgres /home/student/pg_ext_data
*/
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLESPACE ext_tablespace LOCATION '/home/student/pg_ext_data';
-- или
CREATE TABLESPACE test_tablespace OWNER CURRENT_USER LOCATION '/Users/maksimplotnikov/naumen/study_projects/test_tablespace';

SELECT * FROM pg_tablespace
-- или команды psql \db и \db+
--
-- попробуем удалить табличное пространство
DROP TABLESPACE test_tablespace;		-- почему не получилось? потому что не пустая

----------------------------------------------------------------------------------------------------
-- #3 Роли
SELECT * FROM pg_roles where rolname in ('postgres', 'maksimplotnikov');
--
CREATE ROLE role_test;
CREATE ROLE WITH INHERIT IN ROLE <another_role>;
--
CREATE USER user_test WITH INHERIT login IN ROLE role_test PASSWORD '123';
--
SELECT * FROM pg_role;
--
DROP ROLE role_test;

-----------------------------------------------------------------------------------------------------------------------
-- #4 Создание схемы
CREATE SCHEMA <имя_схемы>;
--
CREATE SCHEMA IF NOT EXIST <имя_схемы>;
--
CREATE SCHEMA AUTHORIZATION { имя_пользователя | CURRENT_USER | SESSION_USER };
-
-- Просмотр схем с привязкой пользователей/ролей к ним
SELECT * FROM pg_namespace;
-- Или команды psql
\dn и \dn+
-- в разрезе по таблицам
SELECT * FROM information_schema.tables;
-- просмотр расширений
SELECT * FROM pg_catalog.pg_extension;

--Примеры:
CREATE SCHEMA otus;
CREATE TABLE table_one
(
    id_one INTEGER PRIMARY KEY,
    some_text text
) tablespace test_tablespace;
--
SELECT * FROM information_schema.tables WHERE table_name = 'table_one';
--
CREATE TABLE otus.table_two
(
    id_two INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_one INTEGER REFERENCES table_one (id_one),
    some_text text UNIQUE
) tablespace test_tablespace;

--Для того, чтобы разрешить обращаться пользователю к схеме
GRANT USAGE ON SCHEMA <имя_схемы> TO <имя_пользователя>;
GRANT ALL ON SCHEMA <имя_схемы> TO <имя_пользователя>;

-----------------------------------------------------------------------------------------------------------------------
-- #5 Расширения
CREATE EXTENSION [IF NOT EXIST] <имя_расширения> [WITH] [SCHEMA <schema_name>] [VERSION <version>] [CASCADE]

--Если необходимо поставитьрасширение которое идет в поставке постгреса (можно посмотреть на офф.сайте)
CREATE EXTENSION pg_stat_statements; 
--даст ошибку, потребуются еще манипуляции включая перезапуск сервера 
SELECT * FROM pg_catalog.pg_extension;
-- расширение генерации uuid
CREATE EXTENSION "uuid-ossp";
-- выдаст uuid
select uuid_generate_v1();

-----------------------------------------------------------------------------------------------------------------------
-- #6 Домен - тип данных с ограничением

CREATE DOMAIN <имя> [ AS ] <тип_данных>
[ COLLATE <правило_сортировки> ]
[ DEFAULT <выражение> ]
[ <ограничение> [ ... ] ]
-- Здесь ограничение:
[ CONSTRAINT <имя_ограничения> ]
{ NOT NULL | NULL | CHECK (<выражение>) }

-- К примеру создадим домен строки с проверкой длины 6 символов
CREATE DOMAIN ru_postal_code AS TEXT CHECK ( VALUE ~ '^\d{6}$' );
-- как найти выражение домена
SELECT * FROM information_schema.domains;
SELECT * FROM information_schema.domain_constraints;
SELECT * FROM information_schema.check_constraints WHERE information_schema.constraint_name = 'yes_or_no_check';
--
CREATE TABLE table_domain_check(a1 integer, a2 ru_postal_code);
insert into table_domain_check values (1, '123456'); -- пройдет
insert into table_domain_check values (1, '12345'); -- даст ошибку: ERROR:  value for domain ru_postal_code violates check constraint "ru_postal_code_check"

-----------------------------------------------------------------------------------------------------------------------
-- #7 Создание таблицы (в схеме по умолчанию)
-- Общий пример
CREATE [ 
[ GLOBAL | LOCAL ] { TEMPORARY | TEMP } | UNLOGGED ] TABLE [IF NOT EXISTS ] имя_таблицы 
( 
  [{ имя_столбца тип_данных [ COLLATE правило_сортировки ] [ограничение_столбца [ ... ] ] | ограничение_таблицы | LIKE исходная_таблица [ вариант_копирования ... ] } [, ... ]] 
)
[ INHERITS ( таблица_родитель [, ... ] ) 
]
[ PARTITION BY { RANGE | LIST | HASH } ( { имя_столбца | ( выражение )} [ COLLATE правило_сортировки ] [ класс_операторов ] [, ... ] ) ]
[ USING метод ]
[ WITH ( параметр_хранения [= значение] [, ... ] ) | WITHOUT OIDS ]
[ ON COMMIT { PRESERVE ROWS | DELETE ROWS | DROP } ]
[ TABLESPACE табл_пространство 
---
-- Пример:
CREATE TABLE table_one
(
    id_one      integer PRIMARY KEY,
    some_text   text
) tablespace test_tablespace;
--
CREATE TABLE table_two
(
    id_two      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_one      integer REFERENCES table_one (id_one),
    some_text   text UNIQUE
) tablespace test_tablespace;
--
INSERT INTO table_one (id_one, some_text) VALUES (1, 'one'), (2, 'two');
--
INSERT INTO table_two (id_one, some_text) VALUES (1, '1-1'), (1, '1-2'), (2, '2-1');
--
SELECT * FROM table_one;

-----------------------------------------------------------------------------------------------------------------------
-- #8 Создание таблицы из результатов запроса
CREATE [ [ GLOBAL | LOCAL ] { TEMPORARY | TEMP } | UNLOGGED ]
TABLE [ IF NOT EXISTS ] имя_таблицы
[ (имя_столбца [, ...] ) ]
[ USING метод ]
[ WITH ( параметр_хранения [= значение] [, ... ] ) | WITHOUTOIDS ]
[ ON COMMIT { PRESERVE ROWS | DELETE ROWS | DROP } ]
[ TABLESPACE табл_пространство ]
AS запрос
[ WITH [ NO ] DATA ]
---
-- Примеры:
CREATE TABLE table_three
AS
SELECT T1.id_one, T1.some_text AS first_text, T2.id_two, T2.some_text AS second_text
FROM table_one T1 INNER JOIN table_two T2 ON T2.id_one = T1.id_one;

-----------------------------------------------------------------------------------------------------------------------
-- #9 Копирование СТРУКТУРЫ таблицы без данных
CREATE TABLE copy_of_table_two (LIKE table_two); 

-----------------------------------------------------------------------------------------------------------------------
-- #10 Типизированные таблицы
CREATE [ [ GLOBAL | LOCAL ] { TEMPORARY | TEMP } | UNLOGGED ] TABLE [ IF NOT EXISTS ] имя_таблицы
OF имя_типа [ ( { имя_столбца [ WITH OPTIONS ] [ ограничение_столбца [ ... ] ] | ограничение_таблицы } [, ... ]) ]

[ PARTITION BY { RANGE | LIST | HASH } ( { имя_столбца | ( выражение )} [ COLLATE правило_сортировки ] [ класс_операторов ] [, ... ] ) ]
[ USING метод ]
[ WITH ( параметр_хранения [= значение] [, ... ] ) | WITHOUT OIDS ]
[ ON COMMIT { PRESERVE ROWS | DELETE ROWS | DROP } ]
[ TABLESPACE табл_пространство ]
---
-- Примеры
-- Перенесем таблицу в схему ddl_pract
ALTER TABLE table_one SET SCHEMA ddl_pract;

SELECT * FROM table_one;    -- Почему не работает?



SELECT * FROM ddl_pract.table_one;

-- схема, имя которой совпадает с именем пользователя ():
SELECT current_user;
CREATE SCHEMA master;
CREATE TABLE master.table_one
(
    single_field    integer;
);

CREATE TABLE table_one
(
    single_field    integer;
);
-- \dt \dt ddl_pract.* \dt *.*

SET search_path = ddl_pract, public;
SHOW search_path;
SELECT * FROM table_one;

DROP TABLE master.table_one;


-- перенесем таблицы из ext_tabspace в pg_default
-- SELECT pg_relation_filepath('ddl_pract.table_one');
ALTER TABLE ddl_pract.table_one SET tablespace pg_default;
ALTER TABLE public.table_two SET tablespace pg_default;
-- SELECT pg_relation_filepath('ddl_pract.table_one');

-- Теперь получится:
DROP TABLESPACE ext_tabspace;

-- Преобразуем базу данных в шабALTлон
\c postgres
ALTER DATABASE otus_ddl IS_TEMPLATE true;

-- ALTER DATABASE otus_ddl ALLOW_CONNECTIONS false;

-- Переименуем во избежании недоразумений...
ALTER DATABASE otus_ddl RENAME TO otus_ddl_template;

SELECT  datname, encoding, pg_encoding_to_char(encoding),
        dattablespace, datistemplate, datallowconn
FROM pg_database;


/* 
 возможно придется выполнить
SELECT pg_terminate_backend(pid) FROM pg_catalog.pg_stat_activity WHERE datname = 'otus_ddl';
*/
-- и создадим новую ДБ
CREATE DATABASE ddl_pract TEMPLATE otus_ddl_template;
-- \c ddl_pract

SELECT * FROM ddl_pract.table_one;

-----------------------------------------------------------------------------------------------------------------------
-- #11 Секцианированные таблицы
CREATE [ [ GLOBAL | LOCAL ] { TEMPORARY | TEMP } | UNLOGGED ] TABLE [ IF NOT EXISTS ] имя_таблицы PARTITION OF таблица_родитель [ ( { имя_столбца [ WITH OPTIONS ] [ ограничение_столбца [ ... ] ] | ограничение_таблицы } [, ... ]) ] 
{ FOR VALUES указание_границ_секции | DEFAULT }

[ PARTITION BY { RANGE | LIST | HASH } ( { имя_столбца | ( выражение )} [ COLLATE правило_сортировки ] [ класс_операторов ] [, ... ] ) ]
[ USING метод ]
[ WITH ( параметр_хранения [= значение] [, ... ] ) | WITHOUT OIDS ]
[ ON COMMIT { PRESERVE ROWS | DELETE ROWS | DROP } ]
[ TABLESPACE табл_пространство ]
---
-- Примеры
-- создадим отдельную схему
DROP SCHEMA IF EXISTS part_data CASCADE;
CREATE SCHEMA IF NOT EXISTS part_data;

-- Секционирование по диапазону:
CREATE TABLE part_data.large_log
(
	id integer GENERATED ALWAYS AS IDENTITY,
	log_date date NOT NULL,
	some_text text,
  CONSTRAINT pk_large_log PRIMARY KEY (id, log_date)
) PARTITION BY RANGE (log_date);
--Создадим таблицы для разбивки данных по диапазонам
CREATE TABLE part_data.large_log_2021_11 PARTITION OF part_data.large_log FOR VALUES FROM ('2021-11-01') TO ('2021-12-01');
--
CREATE TABLE part_data.large_log_2021_12 PARTITION OF part_data.large_log FOR VALUES FROM ('2021-12-01') TO ('2022-01-01');
--
CREATE TABLE part_data.large_log_2022_01 PARTITION OF part_data.large_log FOR VALUES FROM ('2022-01-01') TO ('2022-01-31');

INSERT INTO part_data.large_log (log_date, some_text)
VALUES  ('2021-11-01', 'раз'),
        ('2021-11-10', 'два'),
        ('2021-11-30', 'три'),
        ('2021-12-30', 'четыре'),
        ('2021-12-31', 'пять'),
        ('2022-01-01', 'шесть'),
        ('2022-01-01', 'семь');

SELECT * FROM  part_data.large_log;

SELECT * FROM part_data.large_log_2021_11;
SELECT * FROM part_data.large_log_2021_12;
SELECT * FROM part_data.large_log_2022_01;
------------------------------------------
EXPLAIN
SELECT * FROM  part_data.large_log WHERE log_date = '2021-12-10'    -- Поиск данных производится только в large_log_2021_12

INSERT INTO part_data.large_log (log_date, some_text) VALUES  ('2020-10-10', '???');                  -- ошибка!
INSERT INTO part_data.large_log_2022_01 (log_date, some_text) VALUES  ('2020-10-10', '???');          -- ошибка!
INSERT INTO part_data.large_log_2022_01 (id, log_date, some_text) VALUES  (999, '2020-10-10', '???');	-- ошибка!

-- attach, detach
CREATE TABLE part_data.large_log_2021_10 (LIKE part_data.large_log);

INSERT INTO part_data.large_log_2021_10 (id, log_date, some_text)
VALUES  (991, '2021-10-20', 'восемь'),
        (992, '2021-10-21', 'девять'),
        (993, '2021-10-22', 'десять');

ALTER TABLE part_data.large_log
ATTACH PARTITION part_data.large_log_2021_10
FOR VALUES FROM ('2021-10-01') TO ('2021-11-01');

ALTER TABLE part_data.large_log
DETACH PARTITION part_data.large_log_2021_10
------------------------------------------------------------------------------------------------------------------------
DROP SCHEMA IF EXISTS part_data CASCADE;
CREATE SCHEMA IF NOT EXISTS part_data;

-- Секционирование по списку:
CREATE TABLE part_data.large_log
(
	id			integer GENERATED ALWAYS AS IDENTITY,
	log_item_id	integer NOT NULL,
	some_text	text

	,CONSTRAINT pk_large_log PRIMARY KEY (id, log_item_id)
) PARTITION BY LIST (log_item_id);

CREATE TABLE part_data.large_log_137
PARTITION OF part_data.large_log
FOR VALUES IN (1, 3, 7);

CREATE TABLE part_data.large_log_24
PARTITION OF part_data.large_log
FOR VALUES IN (2, 4);

CREATE TABLE part_data.large_log_5
PARTITION OF part_data.large_log
FOR VALUES IN (5);

INSERT INTO part_data.large_log (log_item_id, some_text)
VALUES  (1, 'раз'),
        (1, 'два'),
        (1, 'три'),
        (2, 'четыре'),
        (3, 'пять'),
        (4, 'шесть'),
        (7, 'семь');

SELECT * FROM part_data.large_log;

SELECT * FROM part_data.large_log_137;
SELECT * FROM part_data.large_log_24;
SELECT * FROM part_data.large_log_5;

INSERT INTO part_data.large_log (log_item_id, some_text) VALUES (99, '???');       -- ошибка!
------------------------------------------------------------------------------------------------------------------------
DROP SCHEMA IF EXISTS part_data CASCADE;
CREATE SCHEMA IF NOT EXISTS part_data;

-- Секционирование по хэшу:
CREATE TABLE part_data.large_log
(
	id			integer GENERATED ALWAYS AS IDENTITY,
	log_cost	integer NOT NULL,
	some_text	text

	,CONSTRAINT pk_large_log PRIMARY KEY (id, log_cost)
) PARTITION BY HASH (log_cost);

CREATE TABLE part_data.large_log_00
PARTITION OF part_data.large_log
FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE part_data.large_log_01
PARTITION OF part_data.large_log
FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE part_data.large_log_02
PARTITION OF part_data.large_log
FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE part_data.large_log_03
PARTITION OF part_data.large_log
FOR VALUES WITH (MODULUS 4, REMAINDER 3);

INSERT INTO part_data.large_log (log_cost, some_text)
VALUES  (90, 'раз'),
        (92, 'два'),
        (93, 'три'),
        (94, 'четыре'),
        (95, 'пять'),
        (96, 'шесть'),
        (97, 'семь');

SELECT * FROM part_data.large_log;

SELECT * FROM part_data.large_log_00;
SELECT * FROM part_data.large_log_01;
SELECT * FROM part_data.large_log_02;
SELECT * FROM part_data.large_log_03;
------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-- #8 Представления - будут выполняться каждый раз при вызове
-- Общая структура
CREATE [ OR REPLACE ] [ TEMP | TEMPORARY ] [ RECURSIVE ] VIEW имя [ ( имя_столбца [, ...] ) ]
[ WITH ( имя_параметра_представления [= значение_параметра_представления] [, ... ] ) ] 
AS запрос 
[ WITH [ CASCADED | LOCAL ] CHECK OPTION ]
--
-- Пример:
CREATE VIEW view_one
AS
SELECT T1.id_one, T1.some_text AS first_text, T2.id_two, T2.some_text AS second_text
FROM table_one T1 INNER JOIN table_two T2 ON T2.id_one = T1.id_one;
--
SELECT * FROM view_one;
--
CREATE VIEW single_view
AS
SELECT 'Hello world!';
--
SELECT * FROM single_view;
--
------------------------------------------------------------------------------------------------------------------------
-- #9 Материализованные представления 
-- таблица с данными вьюшки могут рефрешиться и на момент вызова ранее вычисленный результат будет дополняться новыми данными
-- Общая структура
CREATE MATERIALIZED VIEW [ IF NOT EXISTS ] имя_таблицы [ (имя_столбца [, ...] ) ] 
[ USING метод ]
[ WITH ( параметр_хранения [= значение] [, ... ] ) ]
[ TABLESPACE табл_пространство ]
AS запрос
[ WITH [ NO ] DATA 
--
-- Примеры:
CREATE MATERIALIZED VIEW mat_view_one
TABLESPACE test_tablespace
AS
SELECT T1.id_one, T1.some_text AS first_text, T2.id_two, T2.some_text AS second_text
FROM table_one T1 INNER JOIN table_two T2 ON T2.id_one = T1.id_one;
--
SELECT * FROM mat_view_one;
--
INSERT INTO table_two (id_one, some_text) VALUES (2, '2-2'), (2, '2-3');
--
SELECT * FROM view_one;
SELECT * FROM mat_view_one;
--
REFRESH MATERIALIZED VIEW mat_view_one;
SELECT * FROM mat_view_one;
--
-----------------------------------------------------------------------------------------------------------------------
-- #10 Последовательности
-- Общая структура
CREATE [ TEMPORARY | TEMP ] SEQUENCE [ IF NOT EXISTS ] имя
[ AS тип_данных ] [ INCREMENT [ BY ] шаг ] [ MINVALUE мин_значение | NO MINVALUE ] [ MAXVALUE макс_значение | NO MAXVALUE ]
[ START [ WITH ] начало ] 
[ CACHE кеш ] 
[ [ NO ] CYCLE ] 
[ OWNED BY { имя_таблицы.имя_столбца | NONE } ]
-- Примеры
CREATE SEQUENCE seq001 START 10;

SELECT nextval('seq001'::regclass);
SELECT setval('seq001'::regclass, 999, false);
SELECT setval('seq001'::regclass, 999);
--
--CREATE TABLE copy_of_table_two (LIKE table_two)
create sequence seq_copy_table_two increment by 10 start with 100 owned by copy_of_table_two.id_two; 
-- проверить текущее значение последовательности
select currval('seq_copy_table_two');
--выборка последовательности
select * from seq_copy_table_two;
--
select * from copy_of_table_two;
--
insert into copy_of_table_two (id_two, id_one, some_text) 
VALUES (nextval('seq_copy_table_two'), 1, '1-1'), (nextval('seq_copy_table_two'), 1, '1-2'), (nextval('seq_copy_table_two'), 2, '2-1');
-----------------------------------------------------------------------------------------------------------------------
-- #11 Индексы
-- Общая структура
CREATE [ UNIQUE ] INDEX [ CONCURRENTLY ] [ [ IF NOT EXISTS ] имя ] ON [ ONLY ] имя_таблицы [ USING метод ]
( { имя_столбца | ( выражение ) } [ COLLATE правило_сортировки ] [ класс_операторов [ ( параметр_класса_оп = значение [, ... ] ) ] ] [ ASC | DESC ] [ NULLS { FIRST | LAST } ] [, ...] )
[ INCLUDE ( имя_столбца [, ...] ) ]
[ WITH ( параметр_хранения [= значение] [, ... ] ) ]
[ TABLESPACE табл_пространство ]
[ WHERE предикат ]
-- Примеры:
create index div_by_2_id_two on copy_of_table_two(id_one) where (id_one%2 = 0);

-----------------------------------------------------------------------------------------------------------------------
-- #12 Функции
CREATE [ OR REPLACE ] FUNCTION
имя ( [ [ режим_аргумента ] [ имя_аргумента ] тип_аргумента [ { DEFAULT | = }
выражение_по_умолчанию ] [, ...] ] )
[ RETURNS тип_результата
| RETURNS TABLE ( имя_столбца тип_столбца [, ...] ) ]
{ LANGUAGE имя_языка
| TRANSFORM { FOR TYPE имя_типа } [, ... ]
| WINDOW
| { IMMUTABLE | STABLE | VOLATILE }
| [ NOT ] LEAKPROOF
| { CALLED ON NULL INPUT | RETURNS NULL ON NULL INPUT | STRICT }
| { [ EXTERNAL ] SECURITY INVOKER | [ EXTERNAL ] SECURITY DEFINER }
| PARALLEL { UNSAFE | RESTRICTED | SAFE }
| COST стоимость_выполнения
| ROWS строк_в_результате
| SUPPORT вспомогательная_функция
| SET параметр_конфигурации { TO значение | = значение | FROM CURRENT }
| AS 'определение'
| AS 'объектный_файл', 'объектный_символ'
} ...

-----------------------------------------------------------------------------------------------------------------------
-- #13 Изменение объектов
CREATE [ OR REPLACE ] PROCEDURE
имя ( [ [ режим_аргумента ] [ имя_аргумента ] тип_аргумента [
{ DEFAULT | = } выражение_по_умолчанию ] [, ...] ] )
{ LANGUAGE имя_языка
| TRANSFORM { FOR TYPE имя_типа } [, ... ]
| [ EXTERNAL ] SECURITY INVOKER | [ EXTERNAL ] SECURITY
DEFINER
| SET параметр_конфигурации { TO значение | = значение | FROM
CURRENT }
| AS 'определение'
| AS 'объектный_файл', 'объектный_символ'
} ...
-----------------------------------------------------------------------------------------------------------------------
-- #14 Изменение объектов
ALTER [вид объекта] [название объекта] [что меняем]
-----------------------------------------------------------------------------------------------------------------------
-- #15 Изменение таблицы
ALTER TABLE [ IF EXISTS ] [ ONLY ] имя [ * ]
действие [, ... ]
ALTER TABLE [ IF EXISTS ] [ ONLY ] имя [ * ]
RENAME [ COLUMN ] имя_столбца TO новое_имя_столбца
ALTER TABLE [ IF EXISTS ] [ ONLY ] имя [ * ]
RENAME CONSTRAINT имя_ограничения TO имя_нового_ограничения
ALTER TABLE [ IF EXISTS ] имя
RENAME TO новое_имя
ALTER TABLE [ IF EXISTS ] имя
SET SCHEMA новая_схема
ALTER TABLE ALL IN TABLESPACE имя [ OWNED BY имя_роли [, ... ] ]
SET TABLESPACE новое_табл_пространство [ NOWAIT ]
ALTER TABLE [ IF EXISTS ] имя
ATTACH PARTITION имя_секции { FOR VALUES указание_границ_секции | DEFAULT }
ALTER TABLE [ IF EXISTS ] имя
DETACH PARTITION имя_секции
ADD [ COLUMN ] [ IF NOT EXISTS ] имя_столбца тип_данных [ COLLATE правило_сортировки ] [
ограничение_столбца [ ... ] ]
DROP [ COLUMN ] [ IF EXISTS ] имя_столбца [ RESTRICT | CASCADE ]
ALTER [ COLUMN ] имя_столбца [ SET DATA ] TYPE тип_данных [ COLLATE правило_сортировки ] [ USING
выражение ]
ALTER [ COLUMN ] имя_столбца SET DEFAULT выражение
ALTER [ COLUMN ] имя_столбца DROP DEFAULT
ALTER [ COLUMN ] имя_столбца { SET | DROP } NOT NULL
ALTER [ COLUMN ] имя_столбца DROP EXPRESSION [ IF EXISTS ]
ALTER [ COLUMN ] имя_столбца ADD GENERATED { ALWAYS | BY DEFAULT } AS IDENTITY [ (
параметры_последовательности ) ]
ALTER [ COLUMN ] имя_столбца { SET GENERATED { ALWAYS | BY DEFAULT } | SET
параметр_последовательности | RESTART [ [ WITH ] перезапуск ] } [...]
ALTER [ COLUMN ] имя_столбца DROP IDENTITY [ IF EXISTS ]
ALTER [ COLUMN ] имя_столбца SET STATISTICS integer
ALTER [ COLUMN ] имя_столбца SET ( атрибут = значение [, ... ] )
ALTER [ COLUMN ] имя_столбца RESET ( атрибут [, ... ] )
ALTER [ COLUMN ] имя_столбца SET STORAGE { PLAIN | EXTERNAL | EXTENDED | MAIN }
ADD ограничение_таблицы [ NOT VALID ]
ADD ограничение_таблицы_по_индексу
ALTER CONSTRAINT имя_ограничения [ DEFERRABLE | NOT DEFERRABLE ] [ INITIALLY DEFERRED | INITIALLY
IMMEDIATE ]
-----------------------------------------------------------------------------------------------------------------------
-- #16 Удаление объектов
DROP [вид объекта] [название объекта] {CASCADE}