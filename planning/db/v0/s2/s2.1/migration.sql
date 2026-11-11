-- Kidney Care — v0/s2/s2.1 blood pressure measurement context.
-- Source: planning/db/v0/s2/s2.1/s2.1.dbml
--
-- Adds optional measurement context to blood_pressure_readings:
--   arm             left | right
--   posture         sitting | standing | lying
--   is_dialysis_day true | false | null (unknown / not recorded)
--   dialysis_phase  pre_dialysis | post_dialysis (only when is_dialysis_day)
-- All columns are nullable so existing rows stay valid without a backfill.

alter table public.blood_pressure_readings
  add column if not exists arm text,
  add column if not exists posture text,
  add column if not exists is_dialysis_day boolean,
  add column if not exists dialysis_phase text;

alter table public.blood_pressure_readings
  drop constraint if exists blood_pressure_readings_arm_check;
alter table public.blood_pressure_readings
  add constraint blood_pressure_readings_arm_check
  check (arm is null or arm in ('left', 'right'));

alter table public.blood_pressure_readings
  drop constraint if exists blood_pressure_readings_posture_check;
alter table public.blood_pressure_readings
  add constraint blood_pressure_readings_posture_check
  check (posture is null or posture in ('sitting', 'standing', 'lying'));

alter table public.blood_pressure_readings
  drop constraint if exists blood_pressure_readings_dialysis_phase_check;
alter table public.blood_pressure_readings
  add constraint blood_pressure_readings_dialysis_phase_check
  check (
    dialysis_phase is null
    or (
      dialysis_phase in ('pre_dialysis', 'post_dialysis')
      and is_dialysis_day is true
    )
  );

comment on column public.blood_pressure_readings.arm is
  'Arm used for the cuff: left or right. NULL = not recorded.';
comment on column public.blood_pressure_readings.posture is
  'Body position during measurement: sitting, standing or lying. NULL = not recorded.';
comment on column public.blood_pressure_readings.is_dialysis_day is
  'Whether the reading was taken on a dialysis day. NULL = not recorded.';
comment on column public.blood_pressure_readings.dialysis_phase is
  'pre_dialysis or post_dialysis; only allowed when is_dialysis_day is true.';
