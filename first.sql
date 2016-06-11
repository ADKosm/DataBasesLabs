-- noinspection SqlDialectInspectionForFile
insert into name (name, gender) values ('Alex Kosmachev', 'm');

-- фильмы
select * from title
where title like '%zombie%' and production_year >= 1990 and production_year <= 2000;

-- актеры
select * from name
where (name = 'Pegg, Simon' or name = 'Frost, Nick') and id in (
  select person_id from cast_info
  where movie_id = (
    select id from title
    where title = 'Shaun of the Dead' and production_year = 2004
  )
);

-- интересные факты
select info from person_info
where person_id in (
  select id from name
  where (name = 'Pegg, Simon' or name = 'Frost, Nick') and id in (
    select person_id from cast_info
    where movie_id = (
      select id from title
      where title = 'Shaun of the Dead' and production_year = 2004
    )
  )
) and info_type_id = 17;

-- назначение на роли
update cast_info
set person_id = (
  select id from name
  where name = 'Alex Kosmachev'
)
where movie_id = (
  select id from title
  where title = 'Alice in Wonderland' and production_year = 2010 and kind_id = 1 and imdb_index = 'I'
) and role_id = (
  select id from role_type
  where role = 'costume designer'
);

-- просмотр роли
select * from name
where id = (
  select person_id from cast_info
  where movie_id =(
    select id from title
    where title = 'Alice in Wonderland' and production_year = 2010 and kind_id = 1 and imdb_index = 'I'
  )
  and role_id = (
    select id from role_type
    where role = 'costume designer'
  )
);

-- удаление
-- 1180000 = select * from name where name = 'Lautner, Taylor';
delete from cast_info
where person_id = 1180000;
delete from person_info
where person_id = 1180000;
delete from aka_name
where person_id = 1180000;
delete from name
where id = 1180000;

-- количество фильмов у актеров
select count(*) from title
where id in (
  select movie_id from cast_info
  where person_id in (
    select id from name
    where (name = 'Pegg, Simon' or name = 'Frost, Nick') and id in (
      select person_id from cast_info
      where movie_id = (
        select id from title
        where title = 'Shaun of the Dead' and production_year = 2004
      )
    )
  )
) and kind_id = (
  select id from kind_type
  where kind = 'movie'
);

-- статистики
select
  case
    when gender = 'm' then 'Actor'
    when gender = 'f' then 'Actress'
  end as role, count
from (
  select gender, count(*) from name
  where id in (
    select person_id from cast_info
    where role_id in (
      select id from role_type
      where role = 'actor' or role = 'actress'
    )
  )
  group by gender
) as raw;


select
  case
    when production_year>=1900 and production_year<2000 then 'XX'
    when production_year>=2000 and production_year<2100 then 'XXI'
  end as century, avg(count)
from (
  select production_year, count(*) from title
  where production_year >= 1900 and production_year<2100
  group by production_year
) as raw
group by century;


select production_year, avg(count) from (
  select movie_id, count(*) from cast_info
  group by movie_id
) as m_c join title on m_c.movie_id = title.id
 group by production_year;

 ----------------

 select t.title from
 title t
 join movie_info mi on mi.movie_id = t.id
 where t.title like '%zombie%' and
 mi.info = 'USA';

select count(*) from (
 select regexp_matches(t.title, 'zombie', 'i') from
 title t
 join movie_info mi on mi.movie_id = t.id
 where mi.info = 'USA'
) as f;

select t.title, n.name, rt.role, n.gender from
cast_info ci
join name n on n.id = ci.person_id
join role_type rt on rt.id = ci.role_id
join title t on t.id = ci.movie_id
where rt.role = 'actress' and n.gender = 'm';