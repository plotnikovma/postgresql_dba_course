analyze;

select *
from actor
where actor_id between 1 and 10;

select *
from rental
where return_date = null;

select *
from rental
where return_date is null;

select *
from rental
         join inventory
              on rental.inventory_id = inventory.inventory_id
         join film on
    inventory.film_id = film.film_id;

select *
from film
where exists (select 1
              from rental
                       join inventory
                            on rental.inventory_id = inventory.inventory_id
                                and inventory.film_id = film.film_id);

select *
from film
where exists (select *
              from film,
                   rental
                       join inventory
                            on rental.inventory_id = inventory.inventory_id
                                and inventory.film_id = film.film_id);

select *
from actor
where actor_id IN (select actor_id
                   from film_actor
                   where film_id = 3);

select *
from actor
--where first_name = 'HE%';
where first_name like 'HE%';

select *
from actor
where first_name like 'BE_';


select *
from actor
where first_name like '%EN';

select *
from actor
where first_name ilike '%En';

select *
from actor
where first_name ~~ '%EN';
~~* 	!~~	!~~*


select *
from actor
where first_name similar to 'J(O|E)%';

select *
from actor
where first_name ~ 'J[OEA]';

select *
from actor
where first_name like '%E%'
    and actor_id IN (select actor_id
                     from film_actor
                     where film_id = 3)
   or actor_id = 35;

select *
from actor
where first_name like '%E%'
  and (actor_id IN (select actor_id
                    from film_actor
                    where film_id = 3)
    or actor_id = 35);
