-- Fluid / water intake logs (dedicated table, vitals-style).
-- Full diet_fluid_logs with food macros deferred to a later stage.

create table if not exists public.fluid_intake_logs (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  recorded_at timestamptz not null,
  fluid_ml numeric not null,
  source text not null default 'manual',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.fluid_intake_logs is
  'Manual fluid/water intake entries in milliliters.';

comment on column public.fluid_intake_logs.fluid_ml is
  'Canonical unit ml; other units convert at the app layer before storage.';

create index if not exists idx_fluid_intake_patient_time
  on public.fluid_intake_logs (patient_id, recorded_at);

create index if not exists idx_fluid_intake_patient_updated
  on public.fluid_intake_logs (patient_id, updated_at);

drop trigger if exists set_fluid_intake_logs_updated_at on public.fluid_intake_logs;
create trigger set_fluid_intake_logs_updated_at
before update on public.fluid_intake_logs
for each row execute function private.set_updated_at();

alter table public.fluid_intake_logs enable row level security;

drop policy if exists "Patients can view their own fluid intake logs" on public.fluid_intake_logs;
create policy "Patients can view their own fluid intake logs"
  on public.fluid_intake_logs
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

drop policy if exists "Patients can insert their own fluid intake logs" on public.fluid_intake_logs;
create policy "Patients can insert their own fluid intake logs"
  on public.fluid_intake_logs
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

drop policy if exists "Patients can update their own fluid intake logs" on public.fluid_intake_logs;
create policy "Patients can update their own fluid intake logs"
  on public.fluid_intake_logs
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

drop policy if exists "Patients can delete their own fluid intake logs" on public.fluid_intake_logs;
create policy "Patients can delete their own fluid intake logs"
  on public.fluid_intake_logs
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

grant select, insert, update, delete on public.fluid_intake_logs to authenticated;
