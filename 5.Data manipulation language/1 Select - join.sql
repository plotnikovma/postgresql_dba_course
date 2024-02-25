-- самый простой SELECT
SELECT;

-- очень сложный SELECT
SELECT 1 + 5;

-- ужасно сложный SELECT
SELECT 'Hello' || ', ' || 'world!';
SELECT 'Hello' || ', ' || 'world!' || NULL;
SELECT 'Hello' || ', ' || 'world!' || '';
--------------------------------------------------------------------------------------

-- Создание таблиц в файле 0.initializing_tables.sql
SELECT *
FROM book_store.book;

SELECT book_name, isbn
FROM book_store.book;

SELECT book_name, isbn
FROM book_store.book
WHERE isbn = '978-5-699-49800-0'
   OR isbn = '978-5-235-03285-9';
-- так можно записать сложное условие (не забывать про приоритеты операций!)
--
SELECT *
FROM book_store.book
WHERE book_id BETWEEN 3 AND 7; -- закрытый интервал ("отрезок")!
--
SELECT book_name, isbn
FROM book_store.book
WHERE isbn IN ('978-5-699-49800-0', '978-5-235-03285-9');
--
SELECT book_name, isbn
FROM book_store.book
WHERE isbn NOT IN ('978-5-699-49800-0', '978-5-235-03285-9');
--
SELECT book_name, isbn
FROM book_store.book
WHERE isbn IN ('978-5-699-49800-0', '978-5-235-03285-9')
ORDER BY book_name DESC;
--
SELECT book_name, isbn
FROM book_store.book
WHERE isbn = any (array['978-5-699-49800-0', '978-5-235-03285-9']::text[])
ORDER BY book_name DESC;

SELECT book_name, isbn
FROM book_store.book
WHERE book = (4, 'Сикорский', '5-7325-0564-4', NULL, 13)::book_store.book;
--NULL - обязательно!
---------------------------------------------------------------------------------------

-- Использование ф-ций
SELECT *, length(book_name) AS length_of_name
FROM book_store.book;


-- Агрегатные ф-ции, group by
SELECT max(length(book_name)) AS max_length_of_name
FROM book_store.book;

SELECT max(length(book_name)) AS max_length_of_name
FROM book_store.book
GROUP BY genre_id;

SELECT genre_id, max(length(book_name)) AS max_length_of_name
FROM book_store.book
GROUP BY genre_id;

-- как найти жанр (genre_id) для которого mаксимальная длина наименования книжки > 40
-- так - сработает?
SELECT genre_id, max(length(book_name)) AS max_length_of_name
FROM book_store.book
GROUP BY genre_id WHERE max(length(book_name)) > 40;
-- ф-ции можно использовать практически в любой части запроса

-- можно так:
SELECT TMP.*
FROM (SELECT genre_id, max(length(book_name)) AS max_length_of_name
      FROM book_store.book
      GROUP BY genre_id) TMP
WHERE TMP.max_length_of_name > 40;

-- но так проще:
SELECT genre_id, max(length(book_name)) AS max_length_of_name
FROM book_store.book
GROUP BY genre_id
HAVING max(length(book_name)) > 40;

SELECT genre_id, max(length(book_name)) AS max_length_of_name
FROM book_store.book
-- WHERE ...
GROUP BY genre_id
HAVING max(length(book_name)) > 40;

SELECT PC.category_name, max(P.price_value)
FROM book_store.price P
         INNER JOIN book_store.price_category PC ON PC.price_category_no = P.price_category_no
GROUP BY PC.category_name
HAVING max(P.price_value) > 5000.

-- использование регуляров
SELECT 'ABCD' like '__CD';

SELECT 'ABCD' ilike '__cd';

SELECT 'фывфыв' ilike '%ВФЫ%';

SELECT 'фывфыв' SIMILAR TO '%вфы%';

SELECT 'фывфыв' ~* '.*ВФЫ*.';

SELECT 'DDDDD' SIMILAR TO 'D{5}';

SELECT 'ABCD' like '__CD';

SELECT '9153264530' ~ '[0123456789]';

SELECT 'T1' ~ '[0123456789]';
SELECT '3333' SIMILAR TO '%[0123456789]%';
SELECT 'T333' SIMILAR TO '%[0123456789]%';

SELECT '9153264530' SIMILAR TO '[0-9]{10}';
SELECT 'Иван 1' !~* '[0-9]'; -- OK
SELECT 'Иван 1' NOT SIMILAR TO '%[0-9]%'; -- OK

SELECT 'Иван 1' !~ '[[:digit:]]'; -- OK
SELECT 'Иван @1' !~ '[[:cntrl:]]'; -- OK

SELECT 'e' LIKE 'ё';


SELECT book_name, isbn
FROM book_store.book
WHERE isbn = '978-5-699-49800-0'
   OR isbn = '978-5-235-03285-9'
    AND book_name ilike '%ю%';
-- почему???


SELECT book_name, isbn
FROM book_store.book
WHERE (isbn = '978-5-699-49800-0' OR isbn = '978-5-235-03285-9')
  AND book_name ilike '%ю%';

-- а ещё можно так:
SELECT book_name, isbn
FROM book_store.book
WHERE book = (2, 'Введение в системы баз данных', '5-8459-0788-8', NULL, 19)::book


-- Подзапрос
SELECT B.book_name,
       B.isbn,
       (SELECT genre_name FROM book_store.genre G WHERE G.genre_id = B.genre_id)
FROM book_store.book B;


-- или
SELECT book_name,
       isbn
FROM book_store.book
WHERE genre_id = (SELECT genre_id FROM book_store.genre WHERE genre_name = 'Компьютеры и программирования');

-- "=" vs "IN"
SELECT *
FROM book_store.genre;
-- а так сработает?
SELECT book_name,
       isbn
FROM book_store.book
WHERE genre_id = (SELECT genre_id FROM book_store.genre WHERE genre_id > 16);


SELECT book_name,
       isbn
FROM book_store.book
WHERE genre_id IN (SELECT genre_id FROM book_store.genre WHERE genre_id > 16);


-- соединения
-- так будет работать, но это очень плохая практика
EXPLAIN ANALYZE
SELECT B.book_name,
       B.isbn,
       (SELECT genre_name FROM book_store.genre G WHERE G.genre_id = B.genre_id)
FROM book_store.book B
WHERE B.genre_id IN (SELECT genre_id FROM book_store.genre WHERE genre_id > 16);

-- не хочу больше писать полное квалифицированное имя
SET search_path = book_store, public;

-- а как же?
EXPLAIN ANALYZE
SELECT B.book_name,
       B.isbn,
       G.genre_name
FROM book B
         INNER JOIN genre G ON G.genre_id = B.genre_id;

-- "Обратная" задача
SELECT G.genre_name,
       B.book_name,
       B.isbn
FROM book B
         RIGHT JOIN genre G ON G.genre_id = B.genre_id;

-- создадим таблицу без ограничений
CREATE TABLE book_1
AS
SELECT *
FROM book;

INSERT INTO book_1 (book_id, book_name, isbn, published)
VALUES (100001, 'Грамматика английского языка', '5-87852-108-3', 1999),
       (100002, 'Русско-испанский словарь', '978-5-17-044555-4', 2008);

SELECT G.genre_name,
       B.book_name
FROM book_1 B
         -- INNER JOIN genre G ON G.genre_id = B.genre_id;
-- RIGHT JOIN genre G ON G.genre_id = B.genre_id;
-- LEFT JOIN genre G ON G.genre_id = B.genre_id;
-- FULL JOIN genre G ON G.genre_id = B.genre_id;
         CROSS JOIN genre G;


-- найти жанры без книг
-- CREATE INDEX ix_genre_id ON book USING btree (genre_id);

EXPLAIN ANALYZE
SELECT genre_name
FROM genre
WHERE genre_id NOT IN (SELECT genre_id FROM book)
ORDER BY genre_name;
-- это - самый плохой способ

EXPLAIN ANALYZE
SELECT G.genre_name
FROM genre G
WHERE NOT EXISTS (SELECT 1 FROM book B WHERE B.genre_id = G.genre_id)
ORDER BY G.genre_name;

EXPLAIN ANALYZE
SELECT G.genre_name
FROM book B
         RIGHT JOIN genre G ON G.genre_id = B.genre_id
WHERE B.book_id IS NULL
ORDER BY G.genre_name;
---------------------------------------------------------------------------

--в больших таблицах:
DROP TABLE IF EXISTS t_two;
DROP TABLE IF EXISTS t_one;

CREATE TABLE t_one
(
    id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    str text
);

CREATE TABLE t_two
(
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    str    text,

    one_id integer REFERENCES t_one (id)
);

INSERT INTO t_one (str)
SELECT ns::text
FROM generate_series(1, 75000) ns;

INSERT INTO t_two (one_id, str)
SELECT id, str || '+1'
FROM t_one
UNION
SELECT id, str || '+2'
FROM t_one
;

INSERT INTO t_one (str)
SELECT ns::text
FROM generate_series(1, 200000) ns;

SET work_mem = '64MB';

-- CREATE INDEX ix_t_two_id ON t_two USING btree (one_id);

EXPLAIN ANALYZE
SELECT *
FROM t_one
WHERE id NOT IN (SELECT one_id FROM t_two);

EXPLAIN ANALYZE
SELECT t1.*
FROM t_one T1
WHERE NOT EXISTS (SELECT 1 FROM t_two T2 WHERE T2.one_id = T1.id);

EXPLAIN ANALYZE
SELECT t1.*
FROM t_one T1
         RIGHT JOIN t_two T2 ON T2.one_id = T1.id
WHERE T2.id IS NULL;


-- а как влияет наличие/отсутствие индекса на DELETE FROM t_one WHERE?
---------------------------------------------------------------------------

--
SELECT G.genre_name,
       B.book_name
FROM book_1 B,
     genre G;

SELECT G.genre_name,
       B.book_name
FROM book_1 B,
     genre G
WHERE G.genre_id = B.genre_id;
---------------------------------------


SELECT G.genre_name,
       B.book_name
FROM book_1 B
         INNER JOIN genre G USING (genre_id);
-- ON G.genre_id = B.genre_id;

/*
NATURAL — сокращённая форма USING: она образует список USING из всех имён
столбцов, существующих в обеих входных таблицах. Как и с USING, эти столбцы оказываются
в выходной таблице в единственном экземпляре. Если столбцов с одинаковыми именами не
находится, NATURAL JOIN действует как JOIN ... ON TRUE и выдаёт декартово произведение
строк.
*/
-- получим что-нибудь?
SELECT B.*
FROM book B
         NATURAL INNER JOIN book_1 B1;

SELECT *
FROM book B
         NATURAL INNER JOIN genre G;

SELECT B.book_name
     , author_name
     --
     , G.genre_name
FROM book B
         INNER JOIN book_author BA ON BA.book_id = B.book_id
         INNER JOIN author A ON A.author_id = BA.author_id
--
         INNER JOIN genre G ON G.genre_id = B.genre_id;
--------------------------------------------------------------------------------------------

SELECT G.genre_name, B.book_name
FROM book B
         INNER JOIN genre G ON G.genre_id = B.genre_id
    AND G.genre_name ilike '%програм%';

-- будет ли результут отличаться от
SELECT G.genre_name, B.book_name
FROM book B
         INNER JOIN genre G ON G.genre_id = B.genre_id
WHERE G.genre_name ilike '%програм%';

-- А если right или left соединение?
--------------------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SET search_path = book_store, public;

SELECT *
FROM book,
     book_store.price
WHERE book.book_id = price.book_id
  AND price.price_category_no = 1
;

SELECT G.genre_name, max(P.price_value)
FROM book B
         INNER JOIN genre G ON G.genre_id = B.genre_id
         INNER JOIN price P ON B.book_id = P.book_id
--AND P.price_category_no = 1
WHERE P.price_category_no = 1
GROUP BY genre_name
HAVING max(P.price_value) > 1000;

SELECT *
FROM book B
         LEFT JOIN price P ON B.book_id = P.book_id
    AND P.price_category_no = 1;


SELECT *
FROM book
WHERE book_id NOT IN (SELECT book_id FROM price);

SELECT B.*
FROM book B
WHERE NOT EXISTS (SELECT 1 FROM price WHERE price.book_id = B.book_id);


SELECT *--B.*
FROM book B
         LEFT JOIN price P ON B.book_id = P.book_id
    AND P.price_category_no = 1
WHERE price_id IS NULL;
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


SELECT BA.book_id, A.author_name
FROM book_author BA
         INNER JOIN author A ON A.author_id = BA.author_id

SELECT B.*, R.author_name
FROM book B
         INNER JOIN (SELECT BA.book_id, A.author_name
                     FROM book_author BA
                              INNER JOIN author A ON A.author_id = BA.author_id
                     WHERE A.author_name LIKE 'А%') R ON R.book_id = B.book_id;
--------------------------------------------------------------------------------------------

UPDATE book_1
SET genre_id = 18
WHERE book_id = 9;
UPDATE book_2
SET genre_id = 18
WHERE book_id = 9;

CREATE TABLE book_2
AS
SELECT *
FROM book;

INSERT INTO book_2 (book_id, book_name, isbn, published)
VALUES (200001, 'Эволюция физики', '5-93177-020-8', 2001),
       (200002, 'Воскрешение лиственницы', '5-280-01880-5', 2008);

INSERT INTO book_1 (book_id, book_name, isbn)
VALUES (9, 'Рефакторинг. Улучшение существующего кода', '5-93286-045-6', 18);

INSERT INTO book_2 (book_id, book_name, isbn)
VALUES (9, 'Рефакторинг. Улучшение существующего кода', '5-93286-045-6', 18);


SELECT *
FROM book_1
UNION
-- ALL
SELECT *
FROM book_2;

SELECT *
FROM book_1
INTERSECT
-- ALL
SELECT *
FROM book_2;

SELECT *
FROM book_1
EXCEPT
-- ALL
SELECT *
FROM book_2;

SELECT *
FROM book_2
EXCEPT
-- ALL
SELECT *
FROM book_1;

SELECT *
FROM book_1
UNION
-- ALL
SELECT book_name, published
FROM book_2

SELECT *
FROM book_1
UNION
-- ALL
SELECT 999, 'Новая книга', '0-00000-000-0', NULL, 99;


--------------------------------------------------------------------------------------------
INSERT
INTO book_1 (book_id, book_name, isbn, published)
SELECT book_id, book_name, isbn, published
FROM book_2
WHERE book_id > 100000;


SELECT book_id, book_name, isbn, published
INTO book_3
FROM book_2;

SELECT *
FROM book_3;

INSERT INTO book (book_name, isbn, published, genre_id)
VALUES ('Эволюция физики', '5-93177-020-8', 2001, 17),
       ('Воскрешение лиственницы', '5-280-01880-5', 2008, 16)
RETURNING book_id;
-- RETURNING *

INSERT INTO book (book_id, book_name, isbn, published, genre_id)
VALUES (13, 'Частица на краю вселенной', '978-5-9963-1368-6', 2012, 17)
ON CONFLICT (book_id)
    DO UPDATE
    SET book_name = EXCLUDED.book_name,
        isbn      = EXCLUDED.isbn,
        published = EXCLUDED.published,
        genre_id  = EXCLUDED.genre_id;
-- RETURNING *

SELECT *
FROM book;

UPDATE book_3
SET book_id = 3000000
WHERE book_id >= 200001
RETURNING *;

SELECT book_2.*, book_3.*
FROM book_2
         INNER JOIN book_3 ON book_2.book_name = book_3.book_name;

UPDATE book_3 B3
SET book_id = B2.book_id
FROM book_2 B2
WHERE B2.book_name = B3.book_name
  AND B2.isbn IS NOT DISTINCT FROM B3.isbn;


SELECT *
FROM book_2;
SELECT *
FROM book_3;
SELECT *
FROM genre;

-- DELETE
ROLLBACK;
START TRANSACTION;
DELETE
FROM book_2
WHERE book_id > 100;

DELETE
FROM book_2 B2
    USING genre
WHERE B2.genre_id = genre.genre_id
  AND genre.genre_name = 'Биографии авиакострукторов'

SELECT *
FROM book_2;

-- или
DELETE
FROM book_2
WHERE genre_id = (SELECT genre_id FROM genre WHERE genre_name = 'Биографии авиакострукторов');

SELECT *
FROM book_2;

TRUNCATE TABLE book_3;



----------------------------------------------------------------------------------------------------------------------
-- Создание таблицы дней сентябрь 2023
SELECT * into days
FROM generate_series(
  '2023-10-01'::TIMESTAMP,
  '2023-10-01'::TIMESTAMP + INTERVAL '1 month -1 day',
  INTERVAL '1 day'
) AS days(day);


-----
create table departments(id_d serial primary key,
						name_d varchar(50),
						date_create date);
----
insert into departments(name_d, date_create)
values ('юридический','10/20/2023'),
		('бухгалтерия','10/05/2023'),
		('продажи','10/10/2023');
---
create table workers(id_w serial primary key,
		fio varchar(100),
		date_create date,
		id_d integer,
		CONSTRAINT fk_dep_id FOREIGN KEY (id_d)
        REFERENCES public.departments (id_d));

insert into workers(fio, date_create, id_d)
values ('Иванов', '10/09/2023', 1),
		('Савин', '10/09/2023', 2),
		('Клюев', '10/11/2023', 2),
		('Павлов', '10/15/2023', NULL);

--------CROSS JOIN
select * from days cross join departments;

select * from days, departments;

select * from days inner join departments on 1 = 1;
---- 

select * from days inner join departments 
						on day >= date_create;

select * from days inner join departments on 1 = 1
	where day >= date_create;

select * from days inner join departments on true
	where day >= date_create;
	
select * from days cross join departments
	where day >= date_create;	

--- INNER JOIN

select * from departments inner join workers 
		on  departments.id_d = workers.id_d;

select * from departments inner join workers 
		using(id_d);


select * from departments, workers 
	where departments.id_d = workers.id_d;


select * from days, departments inner join workers 
		on departments.id_d = workers.id_d;

select * from days as dys, departments as dpt inner join workers as wrr 
		on dpt.id_d = wrr.id_d;

select * from days as dys, departments as dpt inner join workers as wrr 
		on dys.day >= wrr.date_create;

select * from days as dys cross join departments as dpt inner join workers as wrr 
		on dys.day >= wrr.date_create;

----	using	
select * from departments join workers 
		using(id_d);

----- NATURAL
select * from departments natural join workers; 

select * from departments join workers 
		using(id_d);
		
select * from departments natural join days;


------- Left, Rigth, Full
select * from departments left join workers 
		using(id_d);

select * from departments right join workers 
		using(id_d);

select * from departments full join workers 
		using(id_d);
