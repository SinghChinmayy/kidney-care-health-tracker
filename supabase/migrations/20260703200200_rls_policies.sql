-- Kidney Care — Row-Level Security (planning/sync/v0/stage-1.md §7.3)
-- Every table scopes access to the requesting auth.uid() via patients.auth_user_id.

alter table public.patients enable row level security;
alter table public.blood_pressure_readings enable row level security;
alter table public.blood_glucose_readings enable row level security;
alter table public.weight_readings enable row level security;

create policy patients_owner on public.patients
  for all
  using (auth_user_id = auth.uid())
  with check (auth_user_id = auth.uid());

create policy bp_owner on public.blood_pressure_readings
  for all
  using (patient_id in (select id from public.patients where auth_user_id = auth.uid()))
  with check (patient_id in (select id from public.patients where auth_user_id = auth.uid()));

create policy glucose_owner on public.blood_glucose_readings
  for all
  using (patient_id in (select id from public.patients where auth_user_id = auth.uid()))
  with check (patient_id in (select id from public.patients where auth_user_id = auth.uid()));

create policy weight_owner on public.weight_readings
  for all
  using (patient_id in (select id from public.patients where auth_user_id = auth.uid()))
  with check (patient_id in (select id from public.patients where auth_user_id = auth.uid()));
