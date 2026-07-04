-- Kidney Care - v0/s1/s1.1 patient profile + vitals schema.
-- Source: planning/db/v0/s1/s1.1/s1.1.dbml

create extension if not exists pgcrypto with schema extensions;

create schema if not exists private;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.patients (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id),
  first_name text,
  last_name text,
  date_of_birth date,
  sex text,
  ckd_stage text,
  dialysis_type text default 'none',
  height_cm numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.patients is
  'Core account record, 1:1 with Supabase auth user for v1 (patient-only).';

create index if not exists idx_patients_updated_at
  on public.patients (updated_at);

create table if not exists public.blood_pressure_readings (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  recorded_at timestamptz not null,
  systolic integer,
  diastolic integer,
  heart_rate_bpm integer,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.blood_pressure_readings is
  'BP-only, HR-only, or combined readings are valid; app enforces at least one measurement per row.';

comment on column public.blood_pressure_readings.systolic is 'mmHg';
comment on column public.blood_pressure_readings.diastolic is 'mmHg';
comment on column public.blood_pressure_readings.heart_rate_bpm is 'bpm';

create index if not exists idx_bp_patient_time
  on public.blood_pressure_readings (patient_id, recorded_at);

create index if not exists idx_bp_patient_updated
  on public.blood_pressure_readings (patient_id, updated_at);

create table if not exists public.blood_glucose_readings (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  recorded_at timestamptz not null,
  value_mg_dl numeric not null,
  context text,
  source text not null default 'manual',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on column public.blood_glucose_readings.value_mg_dl is
  'Canonical unit mg/dL; mmol/L input is converted at the app layer before storage.';

comment on column public.blood_glucose_readings.context is
  'Free text placeholder for now, e.g. fasting/post_meal/random/bedtime; formal enum deferred.';

create index if not exists idx_glucose_patient_time
  on public.blood_glucose_readings (patient_id, recorded_at);

create index if not exists idx_glucose_patient_updated
  on public.blood_glucose_readings (patient_id, updated_at);

create table if not exists public.weight_readings (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  recorded_at timestamptz not null,
  value_kg numeric not null,
  source text not null default 'manual',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on column public.weight_readings.value_kg is
  'Canonical unit kg; lb input is converted at the app layer before storage.';

create index if not exists idx_weight_patient_time
  on public.weight_readings (patient_id, recorded_at);

create index if not exists idx_weight_patient_updated
  on public.weight_readings (patient_id, updated_at);

drop trigger if exists set_patients_updated_at on public.patients;
create trigger set_patients_updated_at
before update on public.patients
for each row execute function private.set_updated_at();

drop trigger if exists set_blood_pressure_readings_updated_at on public.blood_pressure_readings;
create trigger set_blood_pressure_readings_updated_at
before update on public.blood_pressure_readings
for each row execute function private.set_updated_at();

drop trigger if exists set_blood_glucose_readings_updated_at on public.blood_glucose_readings;
create trigger set_blood_glucose_readings_updated_at
before update on public.blood_glucose_readings
for each row execute function private.set_updated_at();

drop trigger if exists set_weight_readings_updated_at on public.weight_readings;
create trigger set_weight_readings_updated_at
before update on public.weight_readings
for each row execute function private.set_updated_at();

alter table public.patients enable row level security;
alter table public.blood_pressure_readings enable row level security;
alter table public.blood_glucose_readings enable row level security;
alter table public.weight_readings enable row level security;

drop policy if exists "Patients can view their own profile" on public.patients;
create policy "Patients can view their own profile"
  on public.patients
  for select
  to authenticated
  using ((select auth.uid()) is not null and auth_user_id = (select auth.uid()));

drop policy if exists "Patients can insert their own profile" on public.patients;
create policy "Patients can insert their own profile"
  on public.patients
  for insert
  to authenticated
  with check ((select auth.uid()) is not null and auth_user_id = (select auth.uid()));

drop policy if exists "Patients can update their own profile" on public.patients;
create policy "Patients can update their own profile"
  on public.patients
  for update
  to authenticated
  using ((select auth.uid()) is not null and auth_user_id = (select auth.uid()))
  with check ((select auth.uid()) is not null and auth_user_id = (select auth.uid()));

drop policy if exists "Patients can delete their own profile" on public.patients;
create policy "Patients can delete their own profile"
  on public.patients
  for delete
  to authenticated
  using ((select auth.uid()) is not null and auth_user_id = (select auth.uid()));

drop policy if exists "Patients can view their own blood pressure readings" on public.blood_pressure_readings;
create policy "Patients can view their own blood pressure readings"
  on public.blood_pressure_readings
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

drop policy if exists "Patients can insert their own blood pressure readings" on public.blood_pressure_readings;
create policy "Patients can insert their own blood pressure readings"
  on public.blood_pressure_readings
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

drop policy if exists "Patients can update their own blood pressure readings" on public.blood_pressure_readings;
create policy "Patients can update their own blood pressure readings"
  on public.blood_pressure_readings
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

drop policy if exists "Patients can delete their own blood pressure readings" on public.blood_pressure_readings;
create policy "Patients can delete their own blood pressure readings"
  on public.blood_pressure_readings
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

drop policy if exists "Patients can view their own blood glucose readings" on public.blood_glucose_readings;
create policy "Patients can view their own blood glucose readings"
  on public.blood_glucose_readings
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

drop policy if exists "Patients can insert their own blood glucose readings" on public.blood_glucose_readings;
create policy "Patients can insert their own blood glucose readings"
  on public.blood_glucose_readings
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

drop policy if exists "Patients can update their own blood glucose readings" on public.blood_glucose_readings;
create policy "Patients can update their own blood glucose readings"
  on public.blood_glucose_readings
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

drop policy if exists "Patients can delete their own blood glucose readings" on public.blood_glucose_readings;
create policy "Patients can delete their own blood glucose readings"
  on public.blood_glucose_readings
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

drop policy if exists "Patients can view their own weight readings" on public.weight_readings;
create policy "Patients can view their own weight readings"
  on public.weight_readings
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

drop policy if exists "Patients can insert their own weight readings" on public.weight_readings;
create policy "Patients can insert their own weight readings"
  on public.weight_readings
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

drop policy if exists "Patients can update their own weight readings" on public.weight_readings;
create policy "Patients can update their own weight readings"
  on public.weight_readings
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

drop policy if exists "Patients can delete their own weight readings" on public.weight_readings;
create policy "Patients can delete their own weight readings"
  on public.weight_readings
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

grant usage on schema public to anon, authenticated;

grant select, insert, update, delete on public.patients to authenticated;
grant select, insert, update, delete on public.blood_pressure_readings to authenticated;
grant select, insert, update, delete on public.blood_glucose_readings to authenticated;
grant select, insert, update, delete on public.weight_readings to authenticated;
