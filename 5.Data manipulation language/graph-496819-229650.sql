Есть таблица с описанием ребер графа. У каждого ребра есть своя длина.

create table routes as 
 select 1 as id, 'A' start$ ,'B' end$ ,100 distance
  union all
  select 2,'A' start$,'C' end$,300 distance
  union all
  select 3,'B' start$,'D' end$,200 distance
  union all
  select 4,'B' start$,'C' end$,150 distance
  union all
  select 5,'C' start$,'D' end$,500 distance
  union all
  select 6,'C' start$,'E' end$,400 distance
  union all
  select 7,'D' start$,'A' end$,200 distance
  union all
  select 8,'D' start$,'F' end$,250 distance
  union all
  select 9,'E' start$,'A' end$,300 distance
  union all
  select 10,'E' start$,'B' end$,250 distance),
   search_graph

Нужно:
1) Найти все возможные пути из точки А в точку Е
2) Найти кратчайший путь из точки А в точку Е
3) Найти все кольцевые маршруты (которые начинаются и заканчиваются в одной вершине)
4) Найти все кольцевые маршруты, проходящие через точку С