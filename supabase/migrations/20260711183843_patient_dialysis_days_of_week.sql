-- Add weekly dialysis schedule pattern on patients.
-- JSON array of ISO weekdays: 1=Mon … 7=Sun (e.g. [1,3,5]).
-- null = unset; [] = explicitly no days.

create or replace function private.is_valid_dialysis_days_of_week(days jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select
    days is null
    or (
      jsonb_typeof(days) = 'array'
      and not exists (
        select 1
        from jsonb_array_elements(days) as elem(value)
        where jsonb_typeof(elem.value) <> 'number'
          or trunc((elem.value #>> '{}')::numeric)
            <> (elem.value #>> '{}')::numeric
          or (elem.value #>> '{}')::int < 1
          or (elem.value #>> '{}')::int > 7
      )
      and (
        select count(*)::int
        from jsonb_array_elements(days)
      ) = (
        select count(distinct (elem.value #>> '{}')::int)
        from jsonb_array_elements(days) as elem(value)
      )
    );
$$;

alter table public.patients
  add column if not exists dialysis_days_of_week jsonb;

comment on column public.patients.dialysis_days_of_week is
  'Weekly dialysis days as JSON array of ISO weekdays 1=Mon..7=Sun. '
  'null = unset; [] = no days selected.';

alter table public.patients
  drop constraint if exists patients_dialysis_days_of_week_check;

alter table public.patients
  add constraint patients_dialysis_days_of_week_check
  check (private.is_valid_dialysis_days_of_week(dialysis_days_of_week));
