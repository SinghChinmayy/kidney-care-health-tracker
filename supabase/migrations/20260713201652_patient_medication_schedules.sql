-- Kidney Care — patient_medication_schedules (1:1 with patients).
-- JSON schedule: { "by_day": { "1": ["med-id", ...], ... } } ISO weekdays.

create table if not exists public.patient_medication_schedules (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null unique references public.patients(id),
  schedule jsonb not null default '{"by_day":{}}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.patient_medication_schedules is
  'Per-patient dialysis-day medication bindings. Catalog stays separate; '
  'schedule.by_day maps ISO weekday → medication catalog ids.';

comment on column public.patient_medication_schedules.schedule is
  'JSON: { "by_day": { "1": ["uuid", ...], ... } }. Keys 1=Mon … 7=Sun.';

create index if not exists idx_patient_medication_schedules_updated_at
  on public.patient_medication_schedules (updated_at);

drop trigger if exists set_patient_medication_schedules_updated_at
  on public.patient_medication_schedules;

create trigger set_patient_medication_schedules_updated_at
before insert or update on public.patient_medication_schedules
for each row execute function private.set_updated_at();

alter table public.patient_medication_schedules enable row level security;

drop policy if exists "Patients can view their own medication schedules"
  on public.patient_medication_schedules;

create policy "Patients can view their own medication schedules"
  on public.patient_medication_schedules
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.auth_user_id = (select auth.uid())
    )
  );

drop policy if exists "Patients can insert their own medication schedules"
  on public.patient_medication_schedules;

create policy "Patients can insert their own medication schedules"
  on public.patient_medication_schedules
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.auth_user_id = (select auth.uid())
    )
  );

drop policy if exists "Patients can update their own medication schedules"
  on public.patient_medication_schedules;

create policy "Patients can update their own medication schedules"
  on public.patient_medication_schedules
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.auth_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.auth_user_id = (select auth.uid())
    )
  );

drop policy if exists "Patients can delete their own medication schedules"
  on public.patient_medication_schedules;

create policy "Patients can delete their own medication schedules"
  on public.patient_medication_schedules
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.patients p
      where p.id = patient_id
        and p.auth_user_id = (select auth.uid())
    )
  );

grant select, insert, update, delete
  on public.patient_medication_schedules to authenticated;
