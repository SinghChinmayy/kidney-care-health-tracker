-- s2.3: patient_access-based RLS, create_patient, self-grant protection.
-- Grants are inserted as the migration owner here; the sharing RPCs are
-- covered by 02_sharing_rpcs.test.sql. Run locally with: supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(27);

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
grant execute on function pg_temp.logout() to authenticated;
grant execute on function pg_temp.affected(text) to authenticated;

-- alice (owner of self), bob (stranger), carol (caregiver), victor (viewer).
-- Google-style metadata on alice exercises the bootstrap name prefill.
insert into auth.users (id, email, aud, role, raw_user_meta_data)
values
  ('00000000-0000-0000-0000-00000000000a', 'alice@example.test', 'authenticated', 'authenticated',
   '{"full_name": "Alice Liddell", "provider": "google"}'),
  ('00000000-0000-0000-0000-00000000000b', 'bob@example.test', 'authenticated', 'authenticated', '{}'),
  ('00000000-0000-0000-0000-00000000000c', 'carol@example.test', 'authenticated', 'authenticated', '{}'),
  ('00000000-0000-0000-0000-00000000000d', 'victor@example.test', 'authenticated', 'authenticated', '{}');

create temp table ids as
select
  (select id from public.patients where auth_user_id = '00000000-0000-0000-0000-00000000000a') as alice_patient,
  (select id from public.patients where auth_user_id = '00000000-0000-0000-0000-00000000000b') as bob_patient;
grant select on ids to authenticated;

insert into public.patient_access (patient_id, user_id, role)
select alice_patient, '00000000-0000-0000-0000-00000000000c'::uuid, 'caregiver' from ids
union all
select alice_patient, '00000000-0000-0000-0000-00000000000d'::uuid, 'viewer' from ids;

insert into public.blood_pressure_readings (id, patient_id, recorded_at, systolic, diastolic)
select '10000000-0000-0000-0000-000000000001', alice_patient, now(), 120, 80 from ids;

-- Bootstrap ------------------------------------------------------------------

select is(
  (select role from public.patient_access pa, ids
   where pa.patient_id = ids.alice_patient
     and pa.user_id = '00000000-0000-0000-0000-00000000000a'),
  'owner',
  'signup bootstrap makes the user owner of their self patient'
);

select results_eq(
  $$select first_name, last_name from public.patients p, ids where p.id = ids.alice_patient$$,
  $$values ('Alice'::text, 'Liddell'::text)$$,
  'OAuth signup prefills the self patient name from provider metadata'
);

select results_eq(
  $$select first_name, last_name from public.patients p, ids where p.id = ids.bob_patient$$,
  $$values (null::text, null::text)$$,
  'email signup leaves the name for onboarding'
);

-- Non-member -----------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000b');

select is(
  (select count(*)::int from public.patients p, ids where p.id = ids.alice_patient),
  0, 'non-member cannot read another patient'
);
select is(
  (select count(*)::int from public.blood_pressure_readings r, ids
   where r.patient_id = ids.alice_patient),
  0, 'non-member cannot read another patient''s readings'
);
select throws_ok(
  $$insert into public.blood_pressure_readings (patient_id, recorded_at, systolic, diastolic)
    select alice_patient, now(), 130, 85 from ids$$,
  '42501', null, 'non-member cannot insert readings for another patient'
);
select is(
  pg_temp.affected($$update public.patients set first_name = 'Hacked' where id = (select alice_patient from ids)$$),
  0, 'non-member cannot update another patient'
);
select is(
  pg_temp.affected($$update public.blood_pressure_readings set systolic = 999 where id = '10000000-0000-0000-0000-000000000001'$$),
  0, 'non-member cannot update another patient''s readings'
);
select is(
  pg_temp.affected($$delete from public.blood_pressure_readings where id = '10000000-0000-0000-0000-000000000001'$$),
  0, 'non-member cannot delete another patient''s readings'
);
select throws_ok(
  $$insert into public.patient_access (patient_id, user_id, role)
    select alice_patient, '00000000-0000-0000-0000-00000000000b', 'owner' from ids$$,
  '42501', null, 'non-member cannot self-grant ownership by inserting into patient_access'
);
select throws_ok(
  $$update public.patient_access set role = 'owner'
    where user_id = '00000000-0000-0000-0000-00000000000b'$$,
  '42501', null, 'clients cannot update patient_access'
);
select throws_ok(
  $$delete from public.patient_access$$,
  '42501', null, 'clients cannot delete patient_access rows'
);
select is(
  (select count(*)::int from public.patient_access pa, ids
   where pa.patient_id = ids.alice_patient),
  0, 'non-member cannot see another patient''s access list'
);
select throws_ok(
  $$insert into public.patients (first_name) values ('Direct')$$,
  '42501', null, 'clients cannot insert patients directly'
);
select throws_ok(
  $$select public.create_patient('Mallory', null, (select alice_patient from ids))$$,
  '42501', 'patient_id_conflict', 'create_patient cannot claim an existing patient id'
);
select is(
  (public.create_patient('Grandma', 'B', '20000000-0000-0000-0000-000000000001')).id,
  '20000000-0000-0000-0000-000000000001'::uuid,
  'create_patient accepts a client-generated id'
);
select is(
  (select role from public.patient_access
   where patient_id = '20000000-0000-0000-0000-000000000001'
     and user_id = '00000000-0000-0000-0000-00000000000b'),
  'owner', 'create_patient makes the caller owner'
);
select is(
  (select count(*)::int from public.patient_preferences
   where patient_id = '20000000-0000-0000-0000-000000000001'),
  1, 'created patient gets default preferences and they are readable'
);
select is(
  (public.create_patient('Grandma', 'B', '20000000-0000-0000-0000-000000000001')).first_name,
  'Grandma', 'create_patient is idempotent for the owner'
);

select pg_temp.logout();

-- Owner ----------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select is(
  (select count(*)::int from public.patient_access pa, ids
   where pa.patient_id = ids.alice_patient),
  3, 'owner sees every access row for their patient'
);
select throws_ok(
  $$update public.patients set auth_user_id = '00000000-0000-0000-0000-00000000000b'
    where id = (select alice_patient from ids)$$,
  '42501', null, 'auth_user_id cannot be reassigned'
);
select pg_temp.logout();

-- Caregiver ------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000c');
select lives_ok(
  $$insert into public.blood_pressure_readings (patient_id, recorded_at, systolic, diastolic)
    select alice_patient, now(), 125, 82 from ids$$,
  'caregiver can insert readings'
);
select throws_ok(
  $$update public.patients set deleted_at = now() where id = (select alice_patient from ids)$$,
  '42501', null, 'caregiver cannot soft-delete the patient'
);
select pg_temp.logout();

-- Viewer ---------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000d');
select is(
  (select count(*)::int from public.blood_pressure_readings r, ids
   where r.patient_id = ids.alice_patient),
  2, 'viewer can read readings'
);
select throws_ok(
  $$insert into public.weight_readings (patient_id, recorded_at, value_kg)
    select alice_patient, now(), 70 from ids$$,
  '42501', null, 'viewer cannot insert readings'
);
select is(
  pg_temp.affected($$update public.patient_preferences set daily_water_goal_ml = 5000 where patient_id = (select alice_patient from ids)$$),
  0, 'viewer cannot update preferences'
);
select pg_temp.logout();

-- Revocation (row removed by an owner-side path) -----------------------------

delete from public.patient_access
where user_id = '00000000-0000-0000-0000-00000000000d';

select pg_temp.login('00000000-0000-0000-0000-00000000000d');
select is(
  (select count(*)::int from public.blood_pressure_readings r, ids
   where r.patient_id = ids.alice_patient),
  0, 'revoked user loses read access immediately'
);
select pg_temp.logout();

select * from finish();
rollback;
