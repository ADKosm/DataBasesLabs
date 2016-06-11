-- отчет: молодая компания -> инфа про кино

select cn.name, t.title, mi.info from
movie_companies mc
join company_name cn on cn.id = mc.company_id
join title t on t.id = mc.movie_id
join movie_info mi on mi.movie_id = mc.movie_id
where mc.company_id = (
  with f as (
    select mc.company_id, count(*) from movie_companies mc
    join title t on t.id=mc.movie_id
    where mc.company_type_id = (
      select id from company_type where kind = 'production companies'
    )
    and t.production_year >= (
      select extract(year from now()-interval '5 year')
    )
    group by mc.company_id
  )
  select company_id from f
  where count = (
    select max(count) from f
  )
);

-- отчет: страна -> количество

select mi.info, count(*) from
movie_info mi
join title t on t.id = mi.movie_id
join kind_type kt on kt.id = t.kind_id
where mi.info_type_id = (
  select id from info_type where info = 'countries'
)
and kt.kind = 'movie'
group by mi.info
order by count;

-- фильмы без актеров

with ci as (select movie_id from cast_info where role_id in (
  select id from role_type where role = 'actor' or role = 'actress')
)
select t.title as name, t.id as id,
case when true then 'Film' end as entity,
case when true then 'Film did not contain any actors' end as comment
from title t
left join ci on t.id = ci.movie_id
where ci.movie_id is null and t.kind_id = (select id from kind_type where kind = 'movie');

-- актеры без фильмов

select n.name as name, n.id as id,
case when true then 'Person' end as entity,
case when true then 'Peron did not participate in any movies' end as comment
from
name n
left join cast_info ci on ci.person_id = n.id
where ci.person_id is null;

-- Компании без фильмов
with only_movie as (
    select mc.company_id, mc.movie_id, mc.company_type_id from movie_companies mc
      join title t on t.id = mc.movie_id
    where t.kind_id = (select id from kind_type where kind = 'movie')
)
select cn.name as name, cn.id as id,
CASE
  when true then 'Company'
END as entity,
CASE
  when true then 'Company did not release any movies'
END as comment
from
company_name cn
left join only_movie mc on mc.company_id = cn.id
left join company_type ct on ct.id = mc.company_type_id
where mc.movie_id is null;


-- персонажи без фильмов

select cn.name as name, cn.id as id,
CASE
  when true then 'Character'
END as entity,
CASE
  when true then 'Character did not participate in any movies'
END as comment
from
  char_name cn
  left join cast_info ci on ci.person_role_id = cn.id
  where ci.id is null;

-- общая вьюха

create view problems as (
  with ci as (select movie_id from cast_info where role_id in (
    select id from role_type where role = 'actor' or role = 'actress')
  ),
  only_movie as (
    select mc.company_id, mc.movie_id, mc.company_type_id from movie_companies mc
      join title t on t.id = mc.movie_id
    where t.kind_id = (select id from kind_type where kind = 'movie')
  )
  select t.title as name, t.id as id,
         case when true then 'Film' end as entity,
         case when true then 'Film did not contain any actors' end as comment
  from title t
    left join ci on t.id = ci.movie_id
  where ci.movie_id is null and t.kind_id = (select id from kind_type where kind = 'movie')
  UNION
  select n.name as name, n.id as id,
         case when true then 'Person' end as entity,
         case when true then 'Peron did not participate in any movies' end as comment
  from
    name n
    left join cast_info ci on ci.person_id = n.id
  where ci.person_id is null
  UNION
  select cn.name as name, cn.id as id,
         CASE
         when true then 'Company'
         END as entity,
         CASE
         when true then 'Company did not release any movies'
         END as comment
  from
    company_name cn
    left join only_movie mc on mc.company_id = cn.id
    left join company_type ct on ct.id = mc.company_type_id
  where mc.movie_id is null
  UNION
  select cn.name as name, cn.id as id,
         CASE
         when true then 'Character'
         END as entity,
         CASE
         when true then 'Character did not participate in any movies'
         END as comment
  from
    char_name cn
    left join cast_info ci on ci.person_role_id = cn.id
  where ci.id is null
);

--


-- топ 10 с болшим количеством народу

with max_movies as (
    SELECT DISTINCT
      (ci.movie_id),
      count(*)
      OVER (PARTITION BY ci.movie_id) AS all_people,
      count(is_actor)
      OVER (PARTITION BY ci.movie_id) AS actors
    FROM (
           SELECT
             ci.movie_id,
             CASE
             WHEN ci.role_id IN (SELECT id
                                 FROM role_type
                                 WHERE role = 'actor' OR role = 'actress')
               THEN 1
             END AS is_actor
           FROM cast_info ci
         ) AS ci
    ORDER BY all_people DESC
    LIMIT 10
)
select t.title, mm.all_people, mm.actors from
  max_movies mm
  join title t on t.id = mm.movie_id;

-- топ 10 режиссеров, которые сняли фильмы с большим колиечством народу

with max_movies as (
    select DISTINCT(ci.movie_id), count(*) over (partition by ci.movie_id) as all_people
    from (
           select ci.movie_id
           from cast_info ci
           join title t on t.id = ci.movie_id
           where t.kind_id = (select id from kind_type where kind = 'movie')
         ) as ci
    order by all_people DESC
    limit 30
),
movies_prod as (
    select mm.movie_id, max(cid.person_id) as person_id from
      max_movies mm
      join (
             select * from cast_info where role_id = (select id from role_type where role = 'director')
           ) as cid on cid.movie_id = mm.movie_id
    group by mm.movie_id
    limit 10
), avg_movie as (
    select ddd.person_id, avg(count) from (
                                            select mp.person_id, ci1.movie_id, count(*) from
                                              movies_prod mp
                                              join cast_info ci1 on ci1.person_id = mp.person_id
                                              join cast_info ci2 on ci2.movie_id = ci1.movie_id
                                              group by mp.person_id, ci1.movie_id
                                          ) as ddd
    group by ddd.person_id
), date_info as (
  select * from person_info where info_type_id = (select id from info_type  where info = 'birth date')
), facts_numb as (
  select mp.person_id, count(*) from
    movies_prod mp
    join (
      select * from person_info where info_type_id = (select id from info_type where info = 'trivia')
     ) pi on pi.person_id = mp.person_id
  group by mp.person_id
)
select t.title, mm.all_people , am.avg, n.name, di.info, fn.count from
  movies_prod mp
join title t on t.id = mp.movie_id
join avg_movie am on am.person_id = mp.person_id
join name n on n.id = mp.person_id
left join date_info di on di.person_id = mp.person_id
left join facts_numb fn on fn.person_id = mp.person_id;

---
