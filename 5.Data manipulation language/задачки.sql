----------------------------------
-- 1.Сформировать все возможные комбинации чисел из 100 / 200 / 500 / 1000 для получения 5000
SELECT t, 100 nom, 100 * t amount from generate_series(0, 100) t where 100 * t <= 5000;
-- или
with
    p100 as (SELECT t, 100 nom, 100 * t amount from generate_series(0, 100) t where 100 * t <= 5000),
    p200 as (SELECT t, 200 nom, 200 * t amount from generate_series(0, 100) t where 200 * t <= 5000),
    p500 as (SELECT t, 500 nom, 500 * t amount from generate_series(0, 100) t where 500 * t <= 5000),
    p1000 as (SELECT t, 1000 nom, 1000 * t amount from generate_series(0, 100) t where 1000 * t <= 5000)
SELECT p100.amount, p200.amount, p500.amount, p1000.amount FROM p100
                                                                    cross join p200
                                                                    cross join p500
                                                                    cross join p1000
where p100.amount + p200.amount + p500.amount + p1000.amount = 5000;
-- 2.если у нас есть ограничения на выдачу купюр, к примеру 100 - 50 купюр / 200 - 15 купюр / 500 - 5 купюр / 1000 - 10 купюр
with
    p100 as (SELECT t, 100 nom, 100 * t amount from generate_series(0, 50) t where 100 * t <= 5000),
    p200 as (SELECT t, 200 nom, 200 * t amount from generate_series(0, 15) t where 200 * t <= 5000),
    p500 as (SELECT t, 500 nom, 500 * t amount from generate_series(0, 5) t where 500 * t <= 5000),
    p1000 as (SELECT t, 1000 nom, 1000 * t amount from generate_series(0, 10) t where 1000 * t <= 5000)
SELECT p100.amount, p200.amount, p500.amount, p1000.amount FROM p100
                                                                    cross join p200
                                                                    cross join p500
                                                                    cross join p1000
where p100.amount + p200.amount + p500.amount + p1000.amount = 5000;
-- 3.если из таблицы необходимо удалить записи с повторяющимися ID
create table t_dbls
(
    col1 integer,
    col2 integer
);
--
insert into t_dbls values
(1, 1),
(1, 2),
(1, 2),
(2, 3),
(3, 4),
(3, 4),
(4, 5),
(4, 5),
(4, 5),
(4, 5),
(5, NULL),
(5, NULL);
--
select * from t_dbls order by col1;
-- Решение
with del
    as (
    delete from t_dbls
    returning *
    )
insert into t_dbls
select distinct * from del;
-- 4.