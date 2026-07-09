-- Kidney Care — patient_preferences (1:1 with patients).
-- Source: planning/db/v0/s1/s1.3/s1.3.dbml
--
-- Display/settings only. Vitals stay in canonical units (kg, mg/dL).

create table if not exists public.patient_preferences (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null unique references public.patients(id),
  weight_unit text not null default 'kg',
  blood_glucose_unit text not null default 'mg_dl',
  daily_water_goal_ml integer not null default 1200,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint patient_preferences_weight_unit_check
    check (weight_unit in ('kg', 'lb')),
  constraint patient_preferences_blood_glucose_unit_check
    check (blood_glucose_unit in ('mg_dl', 'mmol_l')),
  constraint patient_preferences_daily_water_goal_ml_check
    check (daily_water_goal_ml > 0)
);

comment on table public.patient_preferences is
  'Per-patient display/settings. Clinical identity stays on patients; '
  'vitals remain canonical units (value_kg, value_mg_dl).';

comment on column public.patient_preferences.patient_id is
  '1:1 with patients; row created with defaults at patient insert (bootstrap).';

comment on column public.patient_preferences.weight_unit is
  'Display/input unit: kg or lb. Storage on weight_readings stays value_kg.';

comment on column public.patient_preferences.blood_glucose_unit is
  'Display/input unit: mg_dl or mmol_l. Storage on blood_glucose_readings stays value_mg_dl.';

comment on column public.patient_preferences.daily_water_goal_ml is
  'Daily recommended fluid intake target in ml.';

create index if not exists idx_patient_preferences_updated_at
  on public.patient_preferences (updated_at);

drop trigger if exists set_patient_preferences_updated_at on public.patient_preferences;

create trigger set_patient_preferences_updated_at
before insert or update on public.patient_preferences
for each row execute function private.set_updated_at();

-- Bootstrap: create default preferences when a patients row is inserted.
create or replace function private.bootstrap_patient_preferences()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.patient_preferences (patient_id)
  values (new.id);
  return new;
end;
$$;

drop trigger if exists trg_bootstrap_patient_preferences on public.patients;

create trigger trg_bootstrap_patient_preferences
after insert on public.patients
for each row execute function private.bootstrap_patient_preferences();

-- Backfill existing patients that do not yet have preferences.
insert into public.patient_preferences (patient_id)
select p.id
from public.patients p
where not exists (
  select 1
  from public.patient_preferences pref
  where pref.patient_id = p.id
);

alter table public.patient_preferences enable row level security;

drop policy if exists "Patients can view their own preferences" on public.patient_preferences;

create policy "Patients can view their own preferences"
  on public.patient_preferences
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.auth_user_id = (select auth.uid())
    )
  );

drop policy if exists "Patients can insert their own preferences" on public.patient_preferences;

create policy "Patients can insert their own preferences"
  on public.patient_preferences
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.auth_user_id = (select auth.uid())
    )
  );

drop policy if exists "Patients can update their own preferences" on public.patient_preferences;

create policy "Patients can update their own preferences"
  on public.patient_preferences
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.auth_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.auth_user_id = (select auth.uid())
    )
  );

drop policy if exists "Patients can delete their own preferences" on public.patient_preferences;

create policy "Patients can delete their own preferences"
  on public.patient_preferences
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.auth_user_id = (select auth.uid())
    )
  );

grant select, insert, update, delete on public.patient_preferences to authenticated;
