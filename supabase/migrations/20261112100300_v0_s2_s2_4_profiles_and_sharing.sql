-- Kidney Care — v0/s2/s2.4 usernames + access-sharing RPCs.
-- Source: planning/db/v0/s2/s2.4/s2.4.dbml
--
-- 1. public.profiles(user_id, username): username chosen by the user, used
--    only to find someone to share with. Emails are never exposed.
-- 2. public.find_user_by_username(username): exact-match lookup returning
--    only (user_id, username).
-- 3. public.list_patient_members(patient_id): members of a patient for any
--    member (viewer+), used for the access screen and recorded_by display.
-- 4. grant / change role / revoke RPCs. Grant and change need owner; revoke
--    needs owner or is the caller leaving. The last owner can never be
--    removed or demoted. The patient's own account (patients.auth_user_id)
--    can never be removed, and only they may change their own role.

-- 1. profiles ----------------------------------------------------------------

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_key unique (username),
  constraint profiles_username_format_check
    check (username ~ '^[a-z0-9_]{3,30}$')
);

comment on table public.profiles is
  'Public handle per auth user, used only for share-by-username lookup. '
  'Readable by its owner only; other users go through RPCs that return the '
  'minimal match.';

comment on column public.profiles.username is
  'Lowercase a-z, 0-9, underscore; 3-30 chars; unique.';

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before insert or update on public.profiles
for each row execute function private.set_updated_at();

alter table public.profiles enable row level security;

create policy "profiles: select own"
  on public.profiles
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "profiles: insert own"
  on public.profiles
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "profiles: update own"
  on public.profiles
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.profiles from anon, authenticated;
grant select, insert, update on public.profiles to authenticated;

-- 2. Lookup ------------------------------------------------------------------

create or replace function public.find_user_by_username(p_username text)
returns table (user_id uuid, username text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  return query
  select pr.user_id, pr.username
  from public.profiles pr
  where pr.username = lower(btrim(coalesce(p_username, '')));
end;
$$;

-- 3. Members -----------------------------------------------------------------

create or replace function public.list_patient_members(p_patient_id uuid)
returns table (
  user_id uuid,
  username text,
  role text,
  is_patient boolean,
  granted_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.has_patient_access(p_patient_id, 'viewer') then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  return query
  select
    pa.user_id,
    pr.username,
    pa.role,
    (p.auth_user_id is not distinct from pa.user_id) as is_patient,
    pa.created_at as granted_at
  from public.patient_access pa
  join public.patients p on p.id = pa.patient_id
  left join public.profiles pr on pr.user_id = pa.user_id
  where pa.patient_id = p_patient_id
  order by private.patient_role_rank(pa.role) desc, pa.created_at;
end;
$$;

-- 4. Grant / change / revoke -------------------------------------------------

create or replace function public.grant_patient_access(
  p_patient_id uuid,
  p_username text,
  p_role text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_target uuid;
begin
  if not private.has_patient_access(p_patient_id, 'owner') then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  if private.patient_role_rank(p_role) is null then
    raise exception 'invalid_role' using errcode = '22023';
  end if;

  select pr.user_id into v_target
  from public.profiles pr
  where pr.username = lower(btrim(coalesce(p_username, '')));

  if v_target is null then
    raise exception 'user_not_found' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.patient_access pa
    where pa.patient_id = p_patient_id and pa.user_id = v_target
  ) then
    raise exception 'already_has_access' using errcode = '23505';
  end if;

  insert into public.patient_access (patient_id, user_id, role, granted_by)
  values (p_patient_id, v_target, p_role, v_uid);
end;
$$;

-- Shared guard for demote/remove: lock owner rows, enforce last-owner and
-- patient-self rules. p_new_role NULL means removal.
create or replace function private.assert_access_change_allowed(
  p_patient_id uuid,
  p_target uuid,
  p_new_role text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_current text;
  v_owner_count integer;
  v_self_user uuid;
begin
  -- Serialise concurrent changes for this patient's owners.
  perform 1
  from public.patient_access pa
  where pa.patient_id = p_patient_id and pa.role = 'owner'
  for update;

  select pa.role into v_current
  from public.patient_access pa
  where pa.patient_id = p_patient_id and pa.user_id = p_target
  for update;

  if v_current is null then
    raise exception 'access_not_found' using errcode = 'P0002';
  end if;

  select p.auth_user_id into v_self_user
  from public.patients p
  where p.id = p_patient_id;

  -- The person the record describes always keeps access to it; only they
  -- may change their own role (still subject to the last-owner rule).
  if v_self_user is not distinct from p_target then
    if p_new_role is null then
      raise exception 'cannot_remove_patient_self' using errcode = '42501';
    end if;
    if p_target <> v_uid then
      raise exception 'cannot_change_patient_self' using errcode = '42501';
    end if;
  end if;

  if v_current = 'owner' and p_new_role is distinct from 'owner' then
    select count(*) into v_owner_count
    from public.patient_access pa
    where pa.patient_id = p_patient_id and pa.role = 'owner';

    if v_owner_count <= 1 then
      raise exception 'last_owner' using errcode = '23514';
    end if;
  end if;

  return v_current;
end;
$$;

revoke all on function private.assert_access_change_allowed(uuid, uuid, text)
  from public;

create or replace function public.change_patient_access_role(
  p_patient_id uuid,
  p_user_id uuid,
  p_role text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.has_patient_access(p_patient_id, 'owner') then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  if private.patient_role_rank(p_role) is null then
    raise exception 'invalid_role' using errcode = '22023';
  end if;

  perform private.assert_access_change_allowed(p_patient_id, p_user_id, p_role);

  update public.patient_access pa
  set role = p_role
  where pa.patient_id = p_patient_id and pa.user_id = p_user_id;
end;
$$;

create or replace function public.revoke_patient_access(
  p_patient_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  -- Owners may remove anyone; any member may remove themselves (leave).
  if p_user_id <> v_uid
     and not private.has_patient_access(p_patient_id, 'owner') then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  if p_user_id = v_uid
     and not private.has_patient_access(p_patient_id, 'viewer') then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  perform private.assert_access_change_allowed(p_patient_id, p_user_id, null);

  delete from public.patient_access pa
  where pa.patient_id = p_patient_id and pa.user_id = p_user_id;
end;
$$;

-- Function privileges: authenticated only.
revoke all on function public.find_user_by_username(text) from public, anon;
revoke all on function public.list_patient_members(uuid) from public, anon;
revoke all on function public.grant_patient_access(uuid, text, text) from public, anon;
revoke all on function public.change_patient_access_role(uuid, uuid, text) from public, anon;
revoke all on function public.revoke_patient_access(uuid, uuid) from public, anon;

grant execute on function public.find_user_by_username(text) to authenticated;
grant execute on function public.list_patient_members(uuid) to authenticated;
grant execute on function public.grant_patient_access(uuid, text, text) to authenticated;
grant execute on function public.change_patient_access_role(uuid, uuid, text) to authenticated;
grant execute on function public.revoke_patient_access(uuid, uuid) to authenticated;
