-- Kidney Care — Core schema (v0/stage-1.2)
-- patients + blood_pressure_readings + blood_glucose_readings + weight_readings
-- See planning/db/v0/stage-1.1.md, planning/db/v0/stage-1.2.md

create extension if not exists pgcrypto;

--------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------

create type ckd_stage as enum (
  'stage_1', 'stage_2', 'stage_3a', 'stage_3b', 'stage_4', 'stage_5', 'dialysis', 'transplant'
);

create type dialysis_type as enum (
  'none', 'hemodialysis', 'peritoneal'
);

create type reading_source as enum (
  'manual', 'device'
);

--------------------------------------------------------------------------
-- patients
--------------------------------------------------------------------------

create table public.patients (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users (id) on delete cascade,
  full_name text,
  date_of_birth date,
  sex text,
  ckd_stage ckd_stage,
  dialysis_type dialysis_type default 'none',
  height_cm numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.patients is 'Core account record, 1:1 with a Supabase auth user for v1 (patient-only). full_name is nullable because the signup bootstrap trigger creates this row before onboarding.';
comment on column public.patients.full_name is 'Nullable: bootstrap trigger creates the row before the user has entered a name; app onboarding fills it in. NULL is treated as "profile incomplete".';

create index idx_patients_updated_at on public.patients (updated_at);

--------------------------------------------------------------------------
-- blood_pressure_readings
--------------------------------------------------------------------------

create table public.blood_pressure_readings (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients (id) on delete cascade,
  recorded_at timestamptz not null,
  systolic integer,
  diastolic integer,
  heart_rate_bpm integer,
  source reading_source not null default 'manual',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.blood_pressure_readings is 'systolic/diastolic and heart_rate_bpm are each independently nullable — at least one of (systolic & diastolic) or heart_rate_bpm should be present, enforced at the app layer.';

create index idx_bp_patient_time on public.blood_pressure_readings (patient_id, recorded_at);
create index idx_bp_patient_updated on public.blood_pressure_readings (patient_id, updated_at);

--------------------------------------------------------------------------
-- blood_glucose_readings
--------------------------------------------------------------------------

create table public.blood_glucose_readings (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients (id) on delete cascade,
  recorded_at timestamptz not null,
  value_mg_dl numeric not null,
  context text,
  source reading_source not null default 'manual',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on column public.blood_glucose_readings.value_mg_dl is 'Canonical unit mg/dL — any mmol/L input is converted at the app layer before storing.';
comment on column public.blood_glucose_readings.context is 'Free text placeholder for now (e.g. fasting/post_meal/random/bedtime) — to become a formal ENUM in a later stage.';

create index idx_glucose_patient_time on public.blood_glucose_readings (patient_id, recorded_at);
create index idx_glucose_patient_updated on public.blood_glucose_readings (patient_id, updated_at);

--------------------------------------------------------------------------
-- weight_readings
--------------------------------------------------------------------------

create table public.weight_readings (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients (id) on delete cascade,
  recorded_at timestamptz not null,
  value_kg numeric not null,
  source reading_source not null default 'manual',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on column public.weight_readings.value_kg is 'Canonical unit kg — any lb input is converted at the app layer before storing.';

create index idx_weight_patient_time on public.weight_readings (patient_id, recorded_at);
create index idx_weight_patient_updated on public.weight_readings (patient_id, updated_at);
