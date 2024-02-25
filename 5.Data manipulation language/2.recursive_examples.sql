WITH RECURSIVE r AS (
    -- стартовая часть рекурсии (т.н. "anchor")
    SELECT 1 AS i,
           1 AS factorial
    UNION
    -- рекурсивная часть 
    SELECT i + 1               AS i,
           factorial * (i + 1) as factorial
    FROM r
    WHERE i < 10)
SELECT *
FROM r;

--SELECT 100!

CREATE TABLE geo
(
    id        int not null primary key,
    parent_id int references geo (id),
    name      varchar(1000)
);

INSERT INTO geo
    (id, parent_id, name)
VALUES (1, null, 'Планета Земля'),
       (2, 1, 'Континент Евразия'),
       (3, 1, 'Континент Северная Америка'),
       (4, 2, 'Европа'),
       (5, 4, 'Россия'),
       (6, 4, 'Германия'),
       (7, 5, 'Москва'),
       (8, 5, 'Санкт-Петербург'),
       (9, 6, 'Берлин');


--не сработает - рекурсия не применима с подзапросами
WITH RECURSIVE r AS (SELECT id, parent_id, name
                     FROM geo
                     WHERE parent_id = 4
                     UNION
                     SELECT id, parent_id
                     FROM geo
                     WHERE parent_id IN (SELECT id
                                         FROM r))
SELECT *
FROM r;
--
WITH RECURSIVE r AS (SELECT id, parent_id, name
                     FROM geo
                     WHERE parent_id = 4
                     UNION
                     SELECT geo.id, geo.parent_id, geo.name
                     FROM geo
                              JOIN r
                                   ON geo.parent_id = r.id)
SELECT *
FROM r;
--
WITH RECURSIVE r AS (SELECT id, parent_id, name::text, 1 AS level
                     FROM geo
                     WHERE id = 4
                     UNION ALL
                     SELECT geo.id, geo.parent_id, geo.name::text, r.level + 1 AS level
                     FROM geo
                              JOIN r
                                   ON geo.parent_id = r.id)
SELECT *
FROM r;
--
WITH RECURSIVE r AS (SELECT id, parent_id, name::text, 1 AS level, null::text as parent_name, name::text as full_name
                     FROM geo
                     WHERE id = 4
                     UNION ALL
                     SELECT geo.id,
                            geo.parent_id,
                            rpad(' ', level * 4) || geo.name::text,
                            r.level + 1                      AS level,
                            r.name                              parent_name,
                            r.full_name || ' \ ' || geo.name as full_name
                     FROM geo
                              JOIN r
                                   ON geo.parent_id = r.id)
SELECT *
FROM r;
--
create table stations
(
    id        integer,
    name      text,
    parent_id integer
);

insert into stations
values (1, 'name', null),
       (2, 'name \ 0', null),
       (3, 'name \ 1', null),
       (4, 'name0', null),
       (5, '1', 1),
       (6, '2', 2),
       (7, '3', 3);


insert into stations
values (11, 'name', null),
       (12, 'name2', null),
       (13, 'name3', null),
       (14, 'name4', null),
       (15, '1', 11),
       (16, '2', 12),
       (17, '3', 13);

WITH RECURSIVE tree AS (SELECT id,
                               name,
                               parent_id,
                               name AS sort_string,
                               1    AS depth
                        FROM stations
                        WHERE parent_id IS NULL
                        UNION ALL
                        SELECT s1.id,
                               s1.name,
                               s1.parent_id,
                               tree.sort_string || ' \ ' || s1.name AS sort_string,
                               tree.depth + 1                       AS depth
                        FROM tree
                                 JOIN stations s1 ON s1.parent_id = tree.id)
SELECT depth, name, id, parent_id, sort_string
FROM tree
ORDER BY sort_string ASC;



create table h
(
    id  int,
    pid int
);

insert into h (id, pid)
values (0, null);
insert into h (id, pid)
values (1, 0);
insert into h (id, pid)
values (2, 1);
insert into h (id, pid)
values (3, 2);
insert into h (id, pid)
values (4, 3);
insert into h (id, pid)
values (5, 4);
insert into h (id, pid)
values (6, 3);
insert into h (id, pid)
values (7, 6);
insert into h (id, pid)
values (8, 7);
insert into h (id, pid)
values (9, 8);
insert into h (id, pid)
values (10, 9);
insert into h (id, pid)
values (11, 10);
insert into h (id, pid)
values (12, 9);
insert into h (id, pid)
values (13, 12);
insert into h (id, pid)
values (14, 8);
insert into h (id, pid)
values (15, 6);
insert into h (id, pid)
values (16, 15);
insert into h (id, pid)
values (17, 6);
insert into h (id, pid)
values (18, 17);
insert into h (id, pid)
values (19, 17);
insert into h (id, pid)
values (20, 3);
insert into h (id, pid)
values (21, 20);
insert into h (id, pid)
values (22, 21);
insert into h (id, pid)
values (23, 22);
insert into h (id, pid)
values (24, 21);

with recursive tree (id, branch, path)
    as
    (select 1           as id
          , ''::text    as branch
          , '001'::text as path
     from (select 'x') x(x)
     union all
     select h.id
          , t.branch || case when ls.id is not null then ' ' else '|' end || '    '
          , t.path || '_' || substr('00000' || h.id, -5)
     from tree t
              left join last_sibling ls
                        on ls.id =
                           t.id
              join h
                   on h.pid =
                      t.id)
   , vertical_space (n)
    as
    (select 1
     from (select 'x') x(x)
     union all
     select vs.n + 1
     from vertical_space vs
     where vs.n < 2)
   , last_sibling (id)
    as
    (select max(id)
     from h
     group by pid)
select t.branch || case vs.n when 1 then '|____' || ' ' || cast(t.id as varchar(10)) else '|' end
from tree t
         cross join vertical_space vs
order by t.path
       , vs.n desc
;

WITH RECURSIVE
    x(i)
        AS (VALUES (0)
            UNION ALL
            SELECT i + 1
            FROM x
            WHERE i < 101),
    Z(Ix, Iy, Cx, Cy, X, Y, I)
        AS (SELECT Ix, Iy, X::float, Y::float, X::float, Y::float, 0
            FROM (SELECT -2.2 + 0.031 * i, i FROM x) AS xgen(x, ix)
                     CROSS JOIN
                     (SELECT -1.5 + 0.031 * i, i FROM x) AS ygen(y, iy)
            UNION ALL
            SELECT Ix, Iy, Cx, Cy, X * X - Y * Y + Cx AS X, Y * X * 2 + Cy, I + 1
            FROM Z
            WHERE X * X + Y * Y < 16.0
              AND I < 27),
    Zt (Ix, Iy, I) AS (SELECT Ix, Iy, MAX(I) AS I
                       FROM Z
                       GROUP BY Iy, Ix
                       ORDER BY Iy, Ix)
SELECT array_to_string(
               array_agg(
                       SUBSTRING(
                               ' .,,,-----++++%%%%@@@@#### ',
                               GREATEST(I, 1),
                               1
                       )
               ), ''
       )
FROM Zt
GROUP BY Iy
ORDER BY Iy;
