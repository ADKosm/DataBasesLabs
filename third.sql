
--добавление индекса
create index cast_info_movie_index on cast_info (movie_id);

-- проверка запроса и измерение скорости его выполнения

explain analyze
select n.name as name, n.id as id,
case when true then 'Person' end as entity,
case when true then 'Peron did not participate in any movies' end as comment
from
name n
left join cast_info ci on ci.person_id = n.id
where ci.person_id is null;

-- ускорение запроса на поиск актеров из первой лабы

create index cast_info_person_index on cast_info(person_id);

--

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

-- использование хеша и проверка того, насколько медленнее после него добавляеся элемент в таблицу

create index person_info_person_index on person_info USING HASH (person_id);

--

explain analyze
insert into title (title, kind_id) values ('Chiki Puki', 1);

