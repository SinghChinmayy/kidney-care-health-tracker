-- RLS + sharing RPC tests for v0/s2 (patient_access, profiles, recorded_by).
-- Run locally with: supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(44);

-- ---------------------------------------------------------------------------
-- Helpers (test-only, rolled back with the transaction)
-- ---------------------------------------------------------------------------

create function pg_temp.login(p_user uuid)
returns void
language plpgsql
as $$
begin
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', p_user, 'role', 'authenticated')::text,
    true
  );
  set local role authenticated;
end;
$$;

create function pg_temp.logout()
returns void
language plpgsql
as $$
begin
  reset role;
  perform set_config('request.jwt.claims', '', true);
end;
$$;

create function pg_temp.self_patient(p_user uuid)
returns uuid
language sql
as $$
  select id from public.patients where auth_user_id = p_user;
$$;

create function pg_temp.affected(p_sql text)
returns integer
language plpgsql
as $$
declare
  n integer;
begin
  execute p_sql;
  get diagnostics n = row_count;
  return n;
end;
$$;

grant execute on function pg_temp.login(uuid) to authenticated;
grant execute on function pg_temp.affected(text) to authenticated;
grant execute on function pg_temp.logout() to authenticated;

-- ---------------------------------------------------------------------------
-- Fixtures: four users; signup trigger creates each self patient + owner row.
-- ---------------------------------------------------------------------------

insert into auth.users (id, email, aud, role)
values
  ('00000000-0000-0000-0000-00000000000a', 'alice@example.test', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000b', 'bob@example.test', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000c', 'carol@example.test', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000d', 'victor@example.test', 'authenticated', 'authenticated');

insert into public.profiles (user_id, username)
values
  ('00000000-0000-0000-0000-00000000000a', 'alice'),
  ('00000000-0000-0000-0000-00000000000b', 'bob'),
  ('00000000-0000-0000-0000-00000000000c', 'carol'),
  ('00000000-0000-0000-0000-00000000000d', 'victor');

create temp table ids as
select
  '00000000-0000-0000-0000-00000000000a'::uuid as alice,
  '00000000-0000-0000-0000-00000000000b'::uuid as bob,
  '00000000-0000-0000-0000-00000000000c'::uuid as carol,
  '00000000-0000-0000-0000-00000000000d'::uuid as victor,
  pg_temp.self_patient('00000000-0000-0000-0000-00000000000a') as alice_patient,
  pg_temp.self_patient('00000000-0000-0000-0000-00000000000b') as bob_patient;
grant select on ids to authenticated;

select is(
  (select role from public.patient_access pa, ids
   where pa.patient_id = ids.alice_patient and pa.user_id = ids.alice),
  'owner',
  'signup bootstrap makes the user owner of their self patient'
);

insert into public.blood_pressure_readings (id, patient_id, recorded_at, systolic, diastolic)
select '10000000-0000-0000-0000-000000000001', alice_patient, now(), 120, 80 from ids;

-- ---------------------------------------------------------------------------
-- Non-member (bob) vs alice's patient
-- ---------------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000b');

select is(
  (select count(*)::int from public.patients p, ids where p.id = ids.alice_patient),
  0,
  'non-member cannot read another patient'
);

select is(
  (select count(*)::int from public.blood_pressure_readings r, ids
   where r.patient_id = ids.alice_patient),
  0,
  'non-member cannot read another patient''s readings'
);

select throws_ok(
  $$insert into public.blood_pressure_readings (patient_id, recorded_at, systolic, diastolic)
    select alice_patient, now(), 130, 85 from ids$$,
  '42501',
  null,
  'non-member cannot insert readings for another patient'
);

select is(
  pg_temp.affected($$update public.patients set first_name = 'Hacked' where id = (select alice_patient from ids)$$),
  0,
  'non-member cannot update another patient'
);

select is(
  pg_temp.affected($$update public.blood_pressure_readings set systolic = 999 where id = '10000000-0000-0000-0000-000000000001'$$),
  0,
  'non-member cannot update another patient''s readings'
);

select throws_ok(
  $$insert into public.patient_access (patient_id, user_id, role)
    select alice_patient, bob, 'owner' from ids$$,
  '42501',
  null,
  'non-member cannot self-grant ownership by inserting into patient_access'
);

select throws_ok(
  $$update public.patient_access set role = 'owner'
    where user_id = '00000000-0000-0000-0000-00000000000b'$$,
  '42501',
  null,
  'clients cannot update patient_access directly'
);

select throws_ok(
  $$select public.grant_patient_access(
      (select alice_patient from ids), 'bob', 'owner')$$,
  '42501',
  'not_authorized',
  'non-member cannot grant themselves access through the RPC'
);

select throws_ok(
  $$select public.create_patient('Mallory', null, (select alice_patient from ids))$$,
  '42501',
  'patient_id_conflict',
  'create_patient cannot claim an existing patient id'
);

select throws_ok(
  $$select * from public.list_patient_members((select alice_patient from ids))$$,
  '42501',
  'not_authorized',
  'non-member cannot list another patient''s members'
);

select is(
  (select count(*)::int from public.profiles where username = 'alice'),
  0,
  'profiles of other users are not directly readable'
);

select results_eq(
  $$select user_id, username from public.find_user_by_username('  ALICE ')$$,
  $$values ('00000000-0000-0000-0000-00000000000a'::uuid, 'alice'::text)$$,
  'username lookup returns only the minimal match (case/space-insensitive)'
);

select throws_ok(
  $$insert into public.patients (auth_user_id, first_name) values (null, 'Direct')$$,
  '42501',
  null,
  'clients cannot insert patients directly (create_patient RPC only)'
);

select pg_temp.logout();

-- ---------------------------------------------------------------------------
-- Owner shares alice's patient: carol caregiver, victor viewer
-- ---------------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');

select lives_ok(
  $$select public.grant_patient_access((select alice_patient from ids), 'Carol', 'caregiver')$$,
  'owner grants caregiver by username'
);

select lives_ok(
  $$select public.grant_patient_access((select alice_patient from ids), 'victor', 'viewer')$$,
  'owner grants viewer by username'
);

select throws_ok(
  $$select public.grant_patient_access((select alice_patient from ids), 'victor', 'caregiver')$$,
  '23505',
  'already_has_access',
  'granting twice is rejected'
);

select throws_ok(
  $$select public.grant_patient_access((select alice_patient from ids), 'nobody', 'viewer')$$,
  'P0002',
  'user_not_found',
  'granting to an unknown username is rejected'
);

select results_eq(
  $$select username, role, is_patient
    from public.list_patient_members((select alice_patient from ids))$$,
  $$values ('alice'::text, 'owner'::text, true),
           ('carol'::text, 'caregiver'::text, false),
           ('victor'::text, 'viewer'::text, false)$$,
  'owner sees all members with roles'
);

select throws_ok(
  $$update public.patients set auth_user_id = '00000000-0000-0000-0000-00000000000b'
    where id = (select alice_patient from ids)$$,
  '42501',
  null,
  'auth_user_id cannot be reassigned'
);

select pg_temp.logout();

-- ---------------------------------------------------------------------------
-- Caregiver (carol)
-- ---------------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000c');

select is(
  (select count(*)::int from public.blood_pressure_readings r, ids
   where r.patient_id = ids.alice_patient),
  1,
  'caregiver can read the shared patient''s readings'
);

select lives_ok(
  $$insert into public.blood_pressure_readings
      (id, patient_id, recorded_at, systolic, diastolic, recorded_by)
    select '10000000-0000-0000-0000-000000000002', alice_patient, now(), 125, 82, alice
    from ids$$,
  'caregiver can insert readings'
);

select is(
  (select recorded_by from public.blood_pressure_readings
   where id = '10000000-0000-0000-0000-000000000002'),
  '00000000-0000-0000-0000-00000000000c'::uuid,
  'recorded_by is forced to auth.uid() (spoofed value ignored)'
);

select is(
  pg_temp.affected($$update public.patients set first_name = 'Alice' where id = (select alice_patient from ids)$$),
  1,
  'caregiver can update the patient profile'
);

select throws_ok(
  $$update public.patients set deleted_at = now()
    where id = (select alice_patient from ids)$$,
  '42501',
  null,
  'caregiver cannot soft-delete the patient'
);

select throws_ok(
  $$select public.grant_patient_access((select alice_patient from ids), 'bob', 'viewer')$$,
  '42501',
  'not_authorized',
  'caregiver cannot grant access'
);

select throws_ok(
  $$select public.change_patient_access_role(
      (select alice_patient from ids), '00000000-0000-0000-0000-00000000000c', 'owner')$$,
  '42501',
  'not_authorized',
  'caregiver cannot promote themselves'
);

select pg_temp.logout();

-- ---------------------------------------------------------------------------
-- Viewer (victor)
-- ---------------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000d');

select is(
  (select count(*)::int from public.blood_pressure_readings r, ids
   where r.patient_id = ids.alice_patient),
  2,
  'viewer can read the shared patient''s readings'
);

select throws_ok(
  $$insert into public.blood_pressure_readings (patient_id, recorded_at, systolic, diastolic)
    select alice_patient, now(), 140, 90 from ids$$,
  '42501',
  null,
  'viewer cannot insert readings'
);

select is(
  pg_temp.affected($$update public.blood_pressure_readings set systolic = 999 where id = '10000000-0000-0000-0000-000000000001'$$),
  0,
  'viewer cannot update readings'
);

select is(
  pg_temp.affected($$update public.patients set first_name = 'Viewer edit' where id = (select alice_patient from ids)$$),
  0,
  'viewer cannot update the patient profile'
);

select pg_temp.logout();

-- recorded_by is immutable on update.
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
update public.blood_pressure_readings
set systolic = 126, recorded_by = '00000000-0000-0000-0000-00000000000a'
where id = '10000000-0000-0000-0000-000000000002';
select pg_temp.logout();

select is(
  (select recorded_by from public.blood_pressure_readings
   where id = '10000000-0000-0000-0000-000000000002'),
  '00000000-0000-0000-0000-00000000000c'::uuid,
  'recorded_by cannot be changed on update'
);

-- ---------------------------------------------------------------------------
-- Revocation
-- ---------------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select lives_ok(
  $$select public.revoke_patient_access(
      (select alice_patient from ids), '00000000-0000-0000-0000-00000000000d')$$,
  'owner revokes viewer'
);
select pg_temp.logout();

select pg_temp.login('00000000-0000-0000-0000-00000000000d');
select is(
  (select count(*)::int from public.blood_pressure_readings r, ids
   where r.patient_id = ids.alice_patient),
  0,
  'revoked user loses read access immediately'
);
select is(
  (select count(*)::int from public.patient_access pa, ids
   where pa.patient_id = ids.alice_patient),
  0,
  'revoked user no longer sees an access row for the patient'
);
select pg_temp.logout();

-- Caregiver leaves on their own.
select pg_temp.login('00000000-0000-0000-0000-00000000000c');
select lives_ok(
  $$select public.revoke_patient_access(
      (select alice_patient from ids), '00000000-0000-0000-0000-00000000000c')$$,
  'member can leave a shared patient'
);
select pg_temp.logout();

-- ---------------------------------------------------------------------------
-- Owner invariants
-- ---------------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select throws_ok(
  $$select public.revoke_patient_access(
      (select alice_patient from ids), '00000000-0000-0000-0000-00000000000a')$$,
  '42501',
  'cannot_remove_patient_self',
  'the patient''s own account can never be removed'
);
select pg_temp.logout();

-- bob creates a patient for someone without an account.
select pg_temp.login('00000000-0000-0000-0000-00000000000b');

select is(
  (public.create_patient('Grandma', 'B', '20000000-0000-0000-0000-000000000001')).id,
  '20000000-0000-0000-0000-000000000001'::uuid,
  'create_patient accepts a client-generated id'
);

select is(
  (select role from public.patient_access
   where patient_id = '20000000-0000-0000-0000-000000000001'
     and user_id = '00000000-0000-0000-0000-00000000000b'),
  'owner',
  'create_patient makes the caller owner'
);

select throws_ok(
  $$select public.revoke_patient_access(
      '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b')$$,
  '23514',
  'last_owner',
  'last owner cannot be removed'
);

select throws_ok(
  $$select public.change_patient_access_role(
      '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'viewer')$$,
  '23514',
  'last_owner',
  'last owner cannot be demoted'
);

select lives_ok(
  $$select public.grant_patient_access('20000000-0000-0000-0000-000000000001', 'alice', 'owner')$$,
  'owner can add a co-owner'
);

select lives_ok(
  $$select public.revoke_patient_access(
      '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b')$$,
  'an owner can leave once another owner exists'
);

select is(
  (select count(*)::int from public.patients
   where id = '20000000-0000-0000-0000-000000000001'),
  0,
  'after leaving, the former owner can no longer read the patient'
);

select pg_temp.logout();

select * from finish();
rollback;
