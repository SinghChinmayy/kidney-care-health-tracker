# Database and synchronization

## Remote schema

The ordered migrations in `supabase/migrations/` currently define:

- `patients`
- `blood_pressure_readings`
- `blood_glucose_readings`
- `weight_readings`
- `patient_preferences`
- `fluid_intake_logs`
- `patient_medication_schedules`

The remote schema uses UUID keys, `created_at`, `updated_at`, and nullable `deleted_at` fields. Vitals use canonical storage units: kg, mg/dL, and ml. Display preferences are stored separately so changing units does not rewrite clinical values. Foreign keys connect readings/preferences/schedules to `patients`; preferences and medication schedules are one-to-one with a patient.

The local Drift schema mirrors these tables and adds `is_dirty` to syncable rows plus a local-only `sync_state` table containing one pull cursor and last-run timestamp per table. Drift migrations preserve local rows as `schemaVersion` advances; the current version is 7.

## Access control

RLS is enabled for the patient and reading tables. Policies scope reads and writes by joining `patient_id` to `patients.auth_user_id = auth.uid()`. Grants are limited to the `authenticated` role for application tables. The current policy model is patient-owner-only; it does not grant caretaker access.

## Sync contract

The `SyncableTable` registry currently contains:

`patients`, `patient_preferences`, `blood_pressure_readings`, `blood_glucose_readings`, `weight_readings`, `fluid_intake_logs`, and `patient_medication_schedules`.

For each table, a run:

1. Reads dirty local rows and upserts them to Supabase.
2. Marks successful pushes clean using the server-returned `updated_at`.
3. Pulls rows for the current patient, optionally filtering by the table cursor.
4. Applies a remote row only if its `updated_at` is newer than the local row.
5. Advances the cursor to the greatest timestamp returned.

Rows are never hard-deleted by the application path: a delete records `deleted_at`, keeps the row dirty, and lets the same sync path propagate the deletion. Active local queries filter deleted rows.

## Security caveat

The client receives only a Supabase publishable/anon key at runtime; no service-role credential belongs in the app. RLS is the security boundary for remote rows. This repository has not been audited for a formal HIPAA/GDPR target, and caretaker authorization is not implemented.
