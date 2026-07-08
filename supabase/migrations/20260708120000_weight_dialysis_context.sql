-- Add dialysis timing and optional weight context to weight_readings.

alter table public.weight_readings
  add column dialysis_timing text not null default 'non_dialysis',
  add column weight_context text;

alter table public.weight_readings
  add constraint weight_readings_dialysis_timing_check
  check (dialysis_timing in ('pre_dialysis', 'post_dialysis', 'non_dialysis'));

comment on column public.weight_readings.dialysis_timing is
  'When the weight was taken relative to dialysis: pre_dialysis, post_dialysis, or non_dialysis.';

comment on column public.weight_readings.weight_context is
  'Optional general context (morning, evening, random, etc.); independent of dialysis_timing.';
