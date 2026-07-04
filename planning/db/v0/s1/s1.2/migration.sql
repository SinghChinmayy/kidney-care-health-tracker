-- Kidney Care — v0/s1/s1.2 patients bootstrap documentation.
-- Source: planning/db/v0/s1/s1.2/s1.2.dbml
--
-- No column DDL change: first_name and last_name were already nullable in s1.1.
-- This slice records the signup-bootstrap contract in schema comments.

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
