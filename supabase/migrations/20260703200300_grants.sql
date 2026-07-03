-- Kidney Care — Data API grants
--
-- Newer Supabase projects no longer auto-expose new public-schema tables to
-- the Data API roles (`anon`/`authenticated`) — see the `auto_expose_new_tables`
-- note in supabase/config.toml. RLS policies (previous migration) restrict
-- *which rows* a role can see; these GRANTs are what allow the role to query
-- the table *at all*. Both are required.
--
-- `anon` is intentionally NOT granted here — every table in this schema is
-- patient-owned data that requires an authenticated session (see sync plan
-- §3.1: "no local writes until authenticated").

grant usage on schema public to authenticated;

grant select, insert, update, delete on public.patients to authenticated;
grant select, insert, update, delete on public.blood_pressure_readings to authenticated;
grant select, insert, update, delete on public.blood_glucose_readings to authenticated;
grant select, insert, update, delete on public.weight_readings to authenticated;
