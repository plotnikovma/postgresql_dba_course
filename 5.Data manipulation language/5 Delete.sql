drop table if exists film_and_actors_stat;

create table film_and_actors_stat
as 
select actor_id, count(*) as film_count, MIN(film_id) as first_film_id, MAX(film_id) as last_film_id
from film_actor 
group by actor_id;


select * from film_and_actors_stat
where film_count < 25;

delete from film_and_actors_stat
where film_count < 15;

---- CTE
drop table if exists film_and_actors_stat_del;
select * into film_and_actors_stat_del from film_and_actors_stat where 1=2;

with t1 as
(
delete from film_and_actors_stat
 where film_count < 25
  returning *
)
insert into film_and_actors_stat_del select * from t1;

select * from film_and_actors_stat_del; 
---

select * from film_and_actors_stat
where exists 
	(select *
	from actor
	where first_name like 'JO%'
		and actor.actor_id = film_and_actors_stat.actor_id);

delete from film_and_actors_stat
where exists 
	(select *
	from actor
	where first_name like 'JO%'
		and actor.actor_id = film_and_actors_stat.actor_id)
returning actor_id;

--error: all rows deleted
select * from film_and_actors_stat
where exists 
	(select *
	from actor
		join film_and_actors_stat as fas
			on fas.actor_id = actor.actor_id
	where first_name like 'JO%');

delete from film_and_actors_stat
where exists 
	(select *
	from actor
		join film_and_actors_stat as fas
			on fas.actor_id = actor.actor_id
	where first_name like 'JO%');

-------- using
select * from film_and_actors_stat, actor
where actor.actor_id = film_and_actors_stat.actor_id
	and actor.first_name like 'JO%';

delete from film_and_actors_stat	
	using actor
where actor.actor_id = film_and_actors_stat.actor_id
	and actor.first_name like 'JO%'
returning film_and_actors_stat.*, actor.*;

------- delete dublicate records

drop table if exists actor_begin;
create table actor_begin
as 
 select *
  from actor
   where actor_id < 6;

select *
 from actor_begin
  order by actor_id;

insert into actor_begin
 select * from actor
  where actor_id between 2 and 3;

select *, ctid from actor_begin;

select actor_id , min(ctid) from actor_begin group by actor_id;

delete from actor_begin a
 using 
  (select actor_id , min(ctid) as s_ctid from actor_begin group by actor_id) s
   where a.ctid <> s.s_ctid and a.actor_id = s.actor_id;

-------------delete/truncate
select count(*) from rental;
drop table if exists rental_del;
select * into rental_del from rental;

--- psql
\timing 
delete from rental_del;

truncate rental_del;