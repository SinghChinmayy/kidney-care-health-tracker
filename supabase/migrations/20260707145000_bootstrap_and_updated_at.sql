-- Kidney Care — v0/s1/s1.2 bootstrap + sync-ready updated_at triggers.
-- Source: planning/db/v0/s1/s1.2/s1.2.dbml, planning/sync/v0/stage-1.md §7.1–7.2
--
-- 1. Document nullable first_name/last_name bootstrap contract (s1.2)
-- 2. Extend set_updated_at triggers to BEFORE INSERT OR UPDATE (sync LWW)
-- 3. Auto-create bare patients row on auth.users signup

comment on table public.patients is
  'Core account record, 1:1 with Supabase auth user for v1 (patient-only). '
  'first_name and last_name are nullable because the signup bootstrap trigger '
  'creates this row before onboarding.';

comment on column public.patients.first_name is
  'Nullable: bootstrap trigger creates the row before the user has entered a name; '
  'app onboarding fills it in. NULL is treated as "profile incomplete".';

comment on column public.patients.last_name is
  'Nullable: bootstrap trigger creates the row before the user has entered a name; '
  'app onboarding fills it in. NULL is treated as "profile incomplete".';

-- Sync: server assigns authoritative updated_at on INSERT and UPDATE.
drop trigger if exists set_patients_updated_at on public.patients;
create trigger set_patients_updated_at
before insert or update on public.patients
for each row execute function private.set_updated_at();

drop trigger if exists set_blood_pressure_readings_updated_at on public.blood_pressure_readings;
create trigger set_blood_pressure_readings_updated_at
before insert or update on public.blood_pressure_readings
for each row execute function private.set_updated_at();

drop trigger if exists set_blood_glucose_readings_updated_at on public.blood_glucose_readings;
create trigger set_blood_glucose_readings_updated_at
before insert or update on public.blood_glucose_readings
for each row execute function private.set_updated_at();

drop trigger if exists set_weight_readings_updated_at on public.weight_readings;
create trigger set_weight_readings_updated_at
before insert or update on public.weight_readings
for each row execute function private.set_updated_at();

-- Bootstrap: create bare patients row when auth user signs up.
create or replace function private.bootstrap_patient_on_signup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.patients (id, auth_user_id)
  values (gen_random_uuid(), new.id);
  return new;
end;
$$;

drop trigger if exists trg_bootstrap_patient on auth.users;
create trigger trg_bootstrap_patient
after insert on auth.users
for each row execute function private.bootstrap_patient_on_signup();
