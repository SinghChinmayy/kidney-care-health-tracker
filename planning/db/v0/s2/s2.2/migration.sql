-- Kidney Care — v0/s2/s2.2 patient blood group + recorded_by attribution.
-- Source: planning/db/v0/s2/s2.2/s2.2.dbml
--
-- 1. patients.blood_group (ABO/Rh, nullable).
-- 2. recorded_by on vitals/log rows, always set server-side from auth.uid()
--    on INSERT and frozen on UPDATE, so clients cannot spoof attribution.
-- 3. blood_glucose_readings.context vocabulary documented to include
--    before_meal (column stays free text; app validates values).

-- 1. Blood group ---------------------------------------------------------

alter table public.patients
  add column if not exists blood_group text;

alter table public.patients
  drop constraint if exists patients_blood_group_check;
alter table public.patients
  add constraint patients_blood_group_check
  check (
    blood_group is null
    or blood_group in ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')
  );

comment on column public.patients.blood_group is
  'ABO/Rh blood group: A+, A-, B+, B-, AB+, AB-, O+, O-. NULL = unknown.';

-- 2. recorded_by ---------------------------------------------------------

create or replace function private.set_recorded_by()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    -- Authenticated callers are always attributed to themselves; the
    -- client-supplied value is ignored. Privileged roles without a JWT
    -- (migrations, service role) may set it explicitly.
    if (select auth.uid()) is not null then
      new.recorded_by := (select auth.uid());
    end if;
  else
    -- Attribution is immutable after insert.
    new.recorded_by := old.recorded_by;
  end if;
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'blood_pressure_readings',
    'blood_glucose_readings',
    'weight_readings',
    'fluid_intake_logs'
  ]
  loop
    execute format(
      'alter table public.%I add column if not exists recorded_by uuid '
      'references auth.users(id) on delete set null',
      t
    );

    execute format(
      'comment on column public.%I.recorded_by is %L',
      t,
      'auth.users id of whoever logged the row. Set from auth.uid() by '
      'trigger on insert; immutable afterwards. NULL = unknown/deleted user.'
    );

    -- Existing rows were all logged by the patient themselves (1:1 era).
    execute format(
      'update public.%I r set recorded_by = p.auth_user_id '
      'from public.patients p '
      'where p.id = r.patient_id and r.recorded_by is null',
      t
    );

    execute format(
      'drop trigger if exists set_%I_recorded_by on public.%I',
      t,
      t
    );
    execute format(
      'create trigger set_%I_recorded_by '
      'before insert or update on public.%I '
      'for each row execute function private.set_recorded_by()',
      t,
      t
    );
  end loop;
end;
$$;

-- 3. Glucose context vocabulary -----------------------------------------

comment on column public.blood_glucose_readings.context is
  'Free text validated by the app: fasting, before_meal, post_meal, random, '
  'bedtime. Formal enum/check deferred until legacy values are audited.';
