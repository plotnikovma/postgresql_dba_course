-- удаление дублей в таблице без ключа:

CREATE SCHEMA IF NOT EXISTS remove_doublies;

SET search_path = remove_doublies, public;

DROP TABLE IF EXISTS t_dbls;

CREATE TABLE t_dbls
(
    col1 integer,
    col2 integer
);

INSERT INTO t_dbls (col1, col2)
VALUES (1, 2),
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

SELECT *
FROM t_dbls
ORDER BY col1;
---------------------------------------------------------------------------------------
-- 1. вариант с with-del
---------------------------------------------------------------------------------------
WITH del
         AS (
        DELETE FROM t_dbls
            RETURNING *)
INSERT
INTO t_dbls
SELECT DISTINCT *
FROM del;


---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- небольшой процент дублей:
TRUNCATE TABLE t_dbls;

INSERT INTO t_dbls (col1, col2)
SELECT n, n + 1
FROM generate_series(1, 500000) n;

INSERT INTO t_dbls (col1, col2)
VALUES (1, 2),
       (1, 2),
       (1, 2),
       (4, 5),
       (4, 5),
       (4, 5),
       (4, 5);

EXPLAIN ANALYZE
WITH del
         AS (
        DELETE FROM t_dbls
            RETURNING *)
INSERT
INTO t_dbls
SELECT DISTINCT *
FROM del;
-- Execution Time: 1318.226 ms

EXPLAIN ANALYZE
WITH del
         AS (
        DELETE FROM t_dbls T
            USING (SELECT col1, col2
                   FROM t_dbls
                   GROUP BY col1, col2
                   HAVING count(*) > 1) R
            WHERE T.col1 = R.col1 AND T.col2 = R.col2
            -- WHERE T = R
            RETURNING T.*)
INSERT
INTO t_dbls
SELECT DISTINCT *
FROM del;
-- Execution Time: 418.548 ms	(Execution Time: ~824.939 ms при сравнении WHERE T = R)


---------------------------------------------------------------------------------------
-- зрачительный процент дублей:
TRUNCATE TABLE t_dbls;

INSERT INTO t_dbls (col1, col2)
SELECT 1, 2
FROM generate_series(1, 100000);

INSERT INTO t_dbls (col1, col2)
SELECT 2, 3
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 3, 4
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 4, 5
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 5, 6
FROM generate_series(1, 100000) n;

EXPLAIN ANALYZE
WITH del
         AS (
        DELETE FROM t_dbls
            RETURNING *)
INSERT
INTO t_dbls
SELECT DISTINCT *
FROM del;
-- Execution Time: 657.221 ms

EXPLAIN ANALYZE
WITH del
         AS (
        DELETE FROM t_dbls T
            USING (SELECT col1, col2
                   FROM t_dbls
                   GROUP BY col1, col2
                   HAVING count(*) > 1) R
            -- WHERE T.col1 = R.col1 AND T.col2 = R.col2
            WHERE T = R
            RETURNING T.*)
INSERT
INTO t_dbls
SELECT DISTINCT *
FROM del;
-- Execution Time: 944.436 ms	(Execution Time: ~1671.010 ms при сравнении WHERE T = R)
---------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------
-- 2. вариант с ctid
-- ctid -- Физическое расположение данной версии строки в таблице. Заметьте, что хотя по ctid можно очень быстро найти версию строки, значение ctid изменится при выполнении VACUUM FULL. Таким образом, ctid нельзя применять в качестве долгосрочного идентификатора строки. Для идентификации логических строк следует использовать первичный ключ.
---------------------------------------------------------------------------------------
TRUNCATE TABLE t_dbls;

INSERT INTO t_dbls (col1, col2)
VALUES (1, 2),
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

SELECT ctid, *
FROM t_dbls;

DELETE
FROM t_dbls T
    USING (SELECT ctid, row_number() OVER (PARTITION BY col1, col2 ORDER BY ctid) rn
           FROM t_dbls) R
WHERE T.ctid = R.ctid
  AND R.rn > 1;

---------------------------------------------------------------------------------------
-- небольшой процент дублей:
TRUNCATE TABLE t_dbls;

INSERT INTO t_dbls (col1, col2)
SELECT n, n + 1
FROM generate_series(1, 500000) n;

INSERT INTO t_dbls (col1, col2)
VALUES (1, 2),
       (1, 2),
       (1, 2),
       (4, 5),
       (4, 5),
       (4, 5),
       (4, 5);

EXPLAIN ANALYZE
DELETE
FROM t_dbls T
    USING (SELECT ctid, row_number() OVER (PARTITION BY col1, col2 ORDER BY ctid) rn
           FROM t_dbls) R
WHERE T.ctid = R.ctid
  AND R.rn > 1;
-- Execution Time: 501.978 ms

SELECT *
FROM t_dbls
ORDER BY col1
LIMIT 100;

---------------------------------------------------------------------------------------
-- зрачительный процент дублей:
TRUNCATE TABLE t_dbls;

INSERT INTO t_dbls (col1, col2)
SELECT 1, 2
FROM generate_series(1, 100000);

INSERT INTO t_dbls (col1, col2)
SELECT 2, 3
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 3, 4
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 4, 5
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 5, 6
FROM generate_series(1, 100000) n;

EXPLAIN ANALYZE
DELETE
FROM t_dbls T
    USING (SELECT ctid, row_number() OVER (PARTITION BY col1, col2 ORDER BY ctid) rn
           FROM t_dbls) R
WHERE T.ctid = R.ctid
  AND R.rn > 1;
-- Execution Time: 1322.129 ms

SELECT *
FROM t_dbls
ORDER BY col1
LIMIT 100;


---------------------------------------------------------------------------------------
-- 2.2 вариант с ctid и MAX (без индекса очень плохо!)
---------------------------------------------------------------------------------------
-- небольшой процент дублей:
TRUNCATE TABLE t_dbls;

INSERT INTO t_dbls (col1, col2)
SELECT n, n + 1
FROM generate_series(1, 500000) n;
--SELECT n, n+1 FROM generate_series(1, 50000) n;

INSERT INTO t_dbls (col1, col2)
VALUES (1, 2),
       (1, 2),
       (1, 2),
       (4, 5),
       (4, 5),
       (4, 5),
       (4, 5);

-- CREATE INDEX ix_t_dbls_cover ON t_dbls USING btree (col1, col2);
REINDEX TABLE t_dbls;

EXPLAIN ANALYZE
DELETE
FROM t_dbls T
WHERE T.ctid <> (SELECT max(ctid)
                 FROM t_dbls R
                 WHERE R.col1 = T.col1
                   AND R.col2 = T.col2);
-- Execution Time: 914.504 ms (с индексом!)

SELECT *
FROM t_dbls
ORDER BY col1
LIMIT 100;
---------------------------------------------------------------------------------------
-- зрачительный процент дублей:
TRUNCATE TABLE t_dbls;

INSERT INTO t_dbls (col1, col2)
SELECT 1, 2
FROM generate_series(1, 100000);

INSERT INTO t_dbls (col1, col2)
SELECT 2, 3
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 3, 4
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 4, 5
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 5, 6
FROM generate_series(1, 100000) n;

REINDEX TABLE t_dbls;

EXPLAIN ANALYZE
DELETE
FROM t_dbls T
WHERE T.ctid <> (SELECT max(ctid)
                 FROM t_dbls R
                 WHERE R.col1 = T.col1
                   AND R.col2 = T.col2);
-- совсем плохо, даже с индексом
---------------------------------------------------------------------------------------	
-- А с временной таблицей?
-- зрачительный процент дублей:
TRUNCATE TABLE t_dbls;

INSERT INTO t_dbls (col1, col2)
SELECT 1, 2
FROM generate_series(1, 100000);

INSERT INTO t_dbls (col1, col2)
SELECT 2, 3
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 3, 4
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 4, 5
FROM generate_series(1, 100000) n;

INSERT INTO t_dbls (col1, col2)
SELECT 5, 6
FROM generate_series(1, 100000) n;


DROP TABLE IF EXISTS tt_ctid;
CREATE TEMP TABLE tt_ctid
(
    id tid
);

INSERT INTO tt_ctid (id)
SELECT max(ctid)
FROM t_dbls R
GROUP BY col1, col2;

-- CREATE INDEX ix_tmp_tt_ctid ON tt_ctid USING btree (id);

EXPLAIN ANALYZE
DELETE
FROM t_dbls
WHERE ctid NOT IN (SELECT id FROM tt_ctid);
-- Execution Time: 395.629 ms (Но затраты на построение времянки)