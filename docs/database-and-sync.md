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
- `patient_access` (who can access which patient, and with which role)
- `profiles` (username used only for sharing)

The remote schema uses UUID keys, `created_at`, `updated_at`, and nullable `deleted_at` fields. Vitals use canonical storage units: kg, mg/dL, and ml. Display preferences are stored separately so changing units does not rewrite clinical values. Foreign keys connect readings/preferences/schedules to `patients`; preferences and medication schedules are one-to-one with a patient.

Log tables carry `recorded_by` (auth user who logged the row), set by a trigger from `auth.uid()` on insert and frozen on update. Blood pressure rows also store optional `arm`, `posture`, `is_dialysis_day` and `dialysis_phase`; patients have an optional `blood_group`. The v0/s2 plan is in `planning/db/v0/s2/`.

The local Drift schema mirrors the synced tables and adds `is_dirty` to syncable rows, plus local-only tables: `sync_state` (pull cursors, stored per table *and patient* as `table:patientId`), `patient_memberships` (cache of the user's own `patient_access` rows) and `local_settings` (the active patient). `profiles` and other members' access rows are not cached. Drift migrations preserve local rows as `schemaVersion` advances; the current version is 10.

## Access control

Every user still gets a *self* patient at signup (`patients.auth_user_id`), but authorization goes through `patient_access(patient_id, user_id, role)`:

| Role | Read | Log/edit vitals, profile, preferences, schedules | Manage access |
|---|---|---|---|
| `owner` | yes | yes | yes |
| `caregiver` | yes | yes | no |
| `viewer` | yes | no | no |

All RLS policies on app tables call one function, `private.has_patient_access(patient_id, min_role)` (SECURITY DEFINER, `search_path = ''`): select needs viewer+, insert/update/delete need caregiver+. `patients` has no client INSERT/DELETE; `auth_user_id` is immutable and soft delete is owner-only (trigger).

Clients have **no** write path into `patient_access` (no policies and no table privileges). It is written only by SECURITY DEFINER functions that check the caller: the signup trigger, `create_patient` (caller becomes owner), and `grant_patient_access` / `change_patient_access_role` / `revoke_patient_access`. The last owner cannot be removed or demoted, and nobody can remove the patient's own account. This closes the archived v1 app's hole, where RLS let any user insert `(auth.uid(), 'owner')` for any patient id. Usernames are looked up with `find_user_by_username`, which returns only `(user_id, username)`.

`supabase/tests/database/*.test.sql` (pgTAP, `supabase test db`) prove that a non-member can't read/write another patient's data or self-grant ownership, a viewer can't write, revoked users lose access, and the last owner can't be removed.

## Sync contract

The `SyncableTable` registry currently contains:

`patients`, `patient_preferences`, `blood_pressure_readings`, `blood_glucose_readings`, `weight_readings`, `fluid_intake_logs`, and `patient_medication_schedules`.

Each run first refreshes access: it fetches the user's own `patient_access` rows and diffs them with `patient_memberships`.

- A patient that disappeared (revoked, or the user left) has all of its cached rows, cursors and membership evicted; if it was active, the app falls back to the self patient.
- A new patient gets its cursors cleared, so the next pull is a full pull regardless of how far other patients' cursors have advanced.
- A patient where the user is now a viewer and still has dirty local rows is evicted and re-pulled (those edits can never be accepted).

Then, for each table:

1. Reads dirty local rows for patients the user can write and upserts them (patients themselves are pushed with `UPDATE` only; they are created server-side).
2. Marks successful pushes clean using the server-returned `updated_at`.
3. Pulls rows for every accessible patient, filtering by that patient's cursor.
4. Applies a remote row only if its `updated_at` is newer than the local row.
5. Advances the patient's cursor to the greatest timestamp returned.

`SyncCoordinator` runs this on startup/resume, two seconds after local writes, on connectivity restoration and every 45 seconds while the app is in the foreground. It exposes a `SyncStatus` (idle/syncing/offline/error) that drives the in-app banner.

Rows are never hard-deleted by the application path: a delete records `deleted_at`, keeps the row dirty, and lets the same sync path propagate the deletion. Active local queries filter deleted rows.

## Security caveat

The client receives only a Supabase publishable/anon key at runtime; no service-role credential belongs in the app. RLS is the security boundary for remote rows. This repository has not been audited for a formal HIPAA/GDPR target. Sharing requires the other person to already have an account and a username; there are no email invitations.
