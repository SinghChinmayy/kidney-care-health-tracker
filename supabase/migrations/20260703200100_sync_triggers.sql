-- Kidney Care — Server-side sync support triggers (planning/sync/v0/stage-1.md §7.1, §7.2)
-- 1) updated_at is server-assigned on every insert/update, eliminating device clock-skew
--    as a source of incorrect last-write-wins outcomes during sync.
-- 2) A bare `patients` row is auto-created on signup so it always exists by the time the
--    client's sync engine runs; app-side onboarding fills in profile fields afterward.

--------------------------------------------------------------------------
-- updated_at trigger, applied to all 4 syncable tables
--------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_patients_updated_at
  before insert or update on public.patients
  for each row execute function public.set_updated_at();

create trigger trg_bp_updated_at
  before insert or update on public.blood_pressure_readings
  for each row execute function public.set_updated_at();

create trigger trg_glucose_updated_at
  before insert or update on public.blood_glucose_readings
  for each row execute function public.set_updated_at();

create trigger trg_weight_updated_at
  before insert or update on public.weight_readings
  for each row execute function public.set_updated_at();

--------------------------------------------------------------------------
-- patients bootstrap trigger on auth.users insert
--------------------------------------------------------------------------

create or replace function public.bootstrap_patient_on_signup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.patients (auth_user_id)
  values (new.id);
  return new;
end;
$$;

create trigger trg_bootstrap_patient
  after insert on auth.users
  for each row execute function public.bootstrap_patient_on_signup();
