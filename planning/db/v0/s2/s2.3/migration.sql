-- Kidney Care — v0/s2/s2.3 patient_access + multi-patient RLS.
-- Source: planning/db/v0/s2/s2.3/s2.3.dbml
--
-- 1. patients.auth_user_id becomes nullable (patients created for someone
--    else have no auth account). It stays UNIQUE: one *self* patient per user.
-- 2. public.patient_access(patient_id, user_id, role) with roles
--    owner > caregiver > viewer. Backfilled: every existing self patient's
--    auth user becomes owner. Signup bootstrap also inserts the owner row.
-- 3. private.has_patient_access(patient_id, min_role) — SECURITY DEFINER,
--    search_path = '' — is the single RLS check for every app table.
-- 4. RLS on all app tables rewritten: read = viewer+, write = caregiver+.
-- 5. public.create_patient(...) RPC: the ONLY way to create a patient from
--    the client; makes the caller owner. No client insert/update/delete
--    policies exist on patient_access (sharing RPCs arrive in s2.4).
--
-- Security note vs. the legacy v1 schema: v1 allowed any user to INSERT
-- (user_id = auth.uid(), role = 'owner') for ANY patient id, i.e. self-grant
-- ownership. That path does not exist here.

-- 1. patients.auth_user_id ---------------------------------------------------

alter table public.patients
  alter column auth_user_id drop not null;

comment on column public.patients.auth_user_id is
  'auth.users id of the person this record describes (their "self" patient). '
  'NULL for patients created for someone without an account. Access control '
  'does NOT use this column; see public.patient_access.';

comment on table public.patients is
  'Patient record. Access is granted per user via public.patient_access '
  '(owner/caregiver/viewer). Every auth user gets a self patient at signup.';

-- 2. patient_access ----------------------------------------------------------

create table if not exists public.patient_access (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null,
  granted_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint patient_access_role_check
    check (role in ('owner', 'caregiver', 'viewer')),
  constraint patient_access_patient_user_key unique (patient_id, user_id)
);

comment on table public.patient_access is
  'Who can access which patient, and how. owner = full access + manage '
  'access; caregiver = read + write vitals/logs/profile; viewer = read-only. '
  'Written only by SECURITY DEFINER functions (signup bootstrap, '
  'create_patient, grant/change/revoke RPCs). Revocation hard-deletes the row.';

create index if not exists idx_patient_access_user
  on public.patient_access (user_id);

drop trigger if exists set_patient_access_updated_at on public.patient_access;
create trigger set_patient_access_updated_at
before insert or update on public.patient_access
for each row execute function private.set_updated_at();

-- Backfill: each existing self patient's user becomes owner.
insert into public.patient_access (patient_id, user_id, role, granted_by)
select p.id, p.auth_user_id, 'owner', p.auth_user_id
from public.patients p
where p.auth_user_id is not null
on conflict (patient_id, user_id) do nothing;

-- 3. Access helpers ----------------------------------------------------------

create or replace function private.patient_role_rank(p_role text)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case p_role
    when 'owner' then 3
    when 'caregiver' then 2
    when 'viewer' then 1
    else null
  end;
$$;

create or replace function private.has_patient_access(
  p_patient_id uuid,
  p_min_role text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.patient_access pa
    where pa.patient_id = p_patient_id
      and pa.user_id = (select auth.uid())
      and private.patient_role_rank(pa.role)
        >= private.patient_role_rank(p_min_role)
  );
$$;

comment on function private.has_patient_access(uuid, text) is
  'True when auth.uid() holds at least p_min_role (viewer < caregiver < owner) '
  'on p_patient_id. SECURITY DEFINER so RLS policies can consult '
  'patient_access without recursive policy evaluation.';

revoke all on function private.patient_role_rank(text) from public;
revoke all on function private.has_patient_access(uuid, text) from public;
grant usage on schema private to authenticated;
grant execute on function private.patient_role_rank(text) to authenticated;
grant execute on function private.has_patient_access(uuid, text) to authenticated;

-- Bootstrap: self patient + owner access row at signup.
create or replace function private.bootstrap_patient_on_signup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_patient_id uuid := gen_random_uuid();
begin
  insert into public.patients (id, auth_user_id)
  values (v_patient_id, new.id);

  insert into public.patient_access (patient_id, user_id, role, granted_by)
  values (v_patient_id, new.id, 'owner', new.id);

  return new;
end;
$$;

-- Guard patient updates that RLS column checks cannot express.
create or replace function private.guard_patient_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    return new; -- migrations / service role
  end if;

  if new.auth_user_id is distinct from old.auth_user_id then
    raise exception 'auth_user_id is immutable'
      using errcode = '42501';
  end if;

  if new.deleted_at is distinct from old.deleted_at
     and not private.has_patient_access(old.id, 'owner') then
    raise exception 'only an owner can delete or restore a patient'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists guard_patient_update on public.patients;
create trigger guard_patient_update
before update on public.patients
for each row execute function private.guard_patient_update();

-- 4. RLS rewrite -------------------------------------------------------------

-- Drop every existing policy on the app tables (old auth_user_id checks).
do $$
declare
  r record;
begin
  for r in
    select tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in (
        'patients',
        'patient_preferences',
        'blood_pressure_readings',
        'blood_glucose_readings',
        'weight_readings',
        'fluid_intake_logs',
        'patient_medication_schedules'
      )
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end;
$$;

-- patients: no INSERT (create_patient RPC / signup trigger) and no DELETE
-- (soft delete via deleted_at, owner-only per guard trigger).
create policy "patients: select viewer+"
  on public.patients
  for select
  to authenticated
  using (private.has_patient_access(id, 'viewer'));

create policy "patients: update caregiver+"
  on public.patients
  for update
  to authenticated
  using (private.has_patient_access(id, 'caregiver'))
  with check (private.has_patient_access(id, 'caregiver'));

revoke insert, delete on public.patients from authenticated;

-- Child tables keyed by patient_id: read viewer+, write caregiver+.
do $$
declare
  t text;
begin
  foreach t in array array[
    'patient_preferences',
    'blood_pressure_readings',
    'blood_glucose_readings',
    'weight_readings',
    'fluid_intake_logs',
    'patient_medication_schedules'
  ]
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated '
      'using (private.has_patient_access(patient_id, %L))',
      t || ': select viewer+', t, 'viewer'
    );
    execute format(
      'create policy %I on public.%I for insert to authenticated '
      'with check (private.has_patient_access(patient_id, %L))',
      t || ': insert caregiver+', t, 'caregiver'
    );
    execute format(
      'create policy %I on public.%I for update to authenticated '
      'using (private.has_patient_access(patient_id, %L)) '
      'with check (private.has_patient_access(patient_id, %L))',
      t || ': update caregiver+', t, 'caregiver', 'caregiver'
    );
    execute format(
      'create policy %I on public.%I for delete to authenticated '
      'using (private.has_patient_access(patient_id, %L))',
      t || ': delete caregiver+', t, 'caregiver'
    );
  end loop;
end;
$$;

-- patient_access: members see their own rows; owners see every row for
-- their patients. No client write policies or privileges at all.
alter table public.patient_access enable row level security;

create policy "patient_access: select own or as owner"
  on public.patient_access
  for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or private.has_patient_access(patient_id, 'owner')
  );

revoke all on public.patient_access from anon, authenticated;
grant select on public.patient_access to authenticated;

-- 5. create_patient RPC ------------------------------------------------------

create or replace function public.create_patient(
  p_first_name text,
  p_last_name text default null,
  p_id uuid default null,
  p_date_of_birth date default null,
  p_sex text default null,
  p_blood_group text default null
)
returns public.patients
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_patient public.patients;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  if nullif(btrim(coalesce(p_first_name, '')), '') is null then
    raise exception 'first_name_required' using errcode = '22023';
  end if;

  -- Idempotent retry with a client-generated id.
  if p_id is not null then
    select * into v_patient from public.patients where id = p_id;
    if found then
      if private.has_patient_access(p_id, 'owner') then
        return v_patient;
      end if;
      raise exception 'patient_id_conflict' using errcode = '42501';
    end if;
  end if;

  insert into public.patients (
    id,
    auth_user_id,
    first_name,
    last_name,
    date_of_birth,
    sex,
    blood_group
  )
  values (
    coalesce(p_id, gen_random_uuid()),
    null,
    btrim(p_first_name),
    nullif(btrim(coalesce(p_last_name, '')), ''),
    p_date_of_birth,
    p_sex,
    p_blood_group
  )
  returning * into v_patient;

  insert into public.patient_access (patient_id, user_id, role, granted_by)
  values (v_patient.id, v_uid, 'owner', v_uid);

  return v_patient;
end;
$$;

comment on function public.create_patient(text, text, uuid, date, text, text) is
  'Creates a patient (no auth account) and makes the caller its owner.';

revoke all on function public.create_patient(text, text, uuid, date, text, text)
  from public, anon;
grant execute on function public.create_patient(text, text, uuid, date, text, text)
  to authenticated;
