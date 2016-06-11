-- исправленная версия функции, исправляющей последовательности в базе (на вики изначально была неправильная)

CREATE OR REPLACE FUNCTION fix_sequences()
  RETURNS void AS $$
   DECLARE max_id INTEGER;
   DECLARE t RECORD;
  BEGIN
   FOR t IN (select table_name from pg_class s
     join information_schema.tables on tables.table_schema = 'public' and table_name=trim(trailing '_id_seq' from relname)
   where s.relkind='S') LOOP
     EXECUTE 'select max(id) from '||t.table_name into max_id; -- выполняет запрос, сформированный в строке и передает результат в max_id
     raise notice 'max id for % is %', t.table_name, max_id;
     if max_id is not null then
        EXECUTE 'SELECT setval('''||t.table_name||'_id_seq'', '||max_id||', true)';
     end if;
   END LOOP;
  END;
  $$ LANGUAGE plpgsql;

-- создание последовательности и самой таблицы для хранения истории company_name

create SEQUENCE company_name_history_id_seq START 1 INCREMENT 1;

create table company_name_history (
  id             integer                 primary key not null default nextval('company_name_history_id_seq'),
  company_id     integer                 not null REFERENCES company_name(id),
  name           text                    not null,
  country_code   character varying(255) ,
  imdb_id        integer                ,
  name_pcode_nf  character varying(5)   ,
  name_pcode_sf  character varying(5)   ,
  md5sum         character varying(32)  ,
  expired_at     date
);

-- функция и триггер для сохранения истории

create or replace function save_company_history() RETURNS trigger as $$
BEGIN
  INSERT INTO company_name_history (company_id, name, country_code, imdb_id, name_pcode_nf, name_pcode_sf, md5sum, expired_at)
    VALUES (OLD.id, OLD.name, OLD.country_code, OLD.imdb_id, OLD.name_pcode_nf, OLD.name_pcode_sf, OLD.md5sum, CURRENT_TIMESTAMP);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

create trigger save_company_history_trigger before insert or update on company_name
  for each row EXECUTE PROCEDURE save_company_history();

-- возраст актера по его имени

create or replace function actor_age(person_name text) returns INTEGER as $$
  DECLARE
    pers_id INTEGER;
    age INTEGER;
    b_date TEXT;
    b_date_int INTEGER;
    d_date TEXT;
    d_date_int INTEGER;
  BEGIN
    SELECT id into pers_id from name where name like '%'||person_name||'%'
    and (imdb_index = 'I' or imdb_index is null) LIMIT 1;
    if not found THEN
      RETURN 0;
    END IF;
    SELECT info into b_date from person_info where info_type_id = 21 and person_id = pers_id;
    IF b_date like '% % %' THEN
      b_date_int := extract(year from TO_DATE(b_date, 'DD MONTH YYYY'));
    ELSE
      b_date_int := extract(year from TO_DATE(b_date, 'YYYY'));
    END IF;
    SELECT info into d_date from person_info where info_type_id = 23 and person_id = pers_id;
    IF not found THEN
      d_date_int := extract(year from now());
    ELSE
      IF d_date like '% % %' THEN
        d_date_int := extract(year from TO_DATE(d_date, 'DD MONTH YYYY'));
      ELSE
        d_date_int := extract(year from TO_DATE(d_date, 'YYYY'));
      END IF;
    END IF;
    RETURN d_date_int - b_date_int-1;
  END;
$$ LANGUAGE plpgsql;

-- информация об актера по его имени

create or replace function actor_info(person_name text) returns void as $$
DECLARE
  pers_id INTEGER;
  nicks TEXT;
  age INTEGER;
  min_year INTEGER;
  film_name TEXT;
BEGIN
  SELECT id into pers_id from name where name like '%'||person_name||'%'
  and (imdb_index = 'I' or imdb_index is null) LIMIT 1;
  if not found THEN
    RAISE EXCEPTION 'Invalid data';
  END IF;
  raise NOTICE 'Name: %', person_name;
  SELECT string_agg(info, ', ') into nicks from person_info where info_type_id = 28 and person_id = pers_id limit 1;
  if found THEN
    raise NOTICE 'Nicknames: %', nicks;
  END IF;
  SELECT actor_age(person_name) into age;
  raise NOTICE 'Age: %', age;
  WITH cast_info_films as (
    select t.title as title, t.production_year as production_year from
    cast_info ci
    join title t on t.id = ci.movie_id
    where ci.person_id = 912128
  )
  SELECT * into film_name, min_year from cast_info_films
    where production_year = (
      select min(production_year) from cast_info_films
    );
  if found THEN
    raise NOTICE 'First appear: %, %', film_name, min_year;
  ELSE
    RAISE EXCEPTION 'Invalid data';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- пример функции, возвращающей таблицу

create or replace function foo(a int)
returns table(b int, c int) as $$
BEGIN
  return query select production_year, kind_id from title where id = a or id = a+1;
END;
$$ LANGUAGE plpgsql;