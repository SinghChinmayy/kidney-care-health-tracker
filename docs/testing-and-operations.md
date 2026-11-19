# Testing and operations

## Reproducible commands

Run from `app/`:

```bash
flutter --version
flutter analyze
flutter test
```

Verification performed on 2026-11-12 with Flutter 3.44.3 and Dart 3.12.2 (v1 feature port branch):

- `flutter analyze`: no errors or warnings; 57 informational issues (same count as before the port), so the command still exits 1.
- `flutter test`: 219 tests; 215 passed, 4 failed. The failures are the pre-existing, date-dependent "shows max 3 readings per week and a N-more row" tests in the blood glucose / blood pressure / weight view tests and "tapping N-more row expands all readings for that week" in the blood pressure view test.
- `supabase test db` (pgTAP, `supabase/tests/database/`): 71 tests passed on a local stack after `supabase db reset`. They cover non-member read/write denial, self-granted ownership attempts (direct insert/update/delete on `patient_access` and the RPCs), viewer write denial, `recorded_by` spoofing, revocation, last-owner and patient-self protections, and username lookup.
- Migrations were also applied on top of a database seeded at the previous schema (`supabase db reset --version 20260713201652`, then `supabase migration up`) to check the `patient_access` and `recorded_by` backfills.

Earlier verification on 2026-09-24:

- `flutter --version`: passed; reported Flutter 3.44.3 / Dart 3.12.2.
- `flutter analyze`: completed with no analyzer errors, but exited 1 because it reported 52 informational issues. The largest group is `prefer_initializing_formals`; there are also style warnings and a test-only `depend_on_referenced_packages` warning.
- `flutter test`: 156 tests executed; 151 passed and 5 failed.

The five failing tests are:

- `ui/features/vitals/view_models/fluid_intake_view_model_test.dart`: daily fluid statistics expected 500 but received 250.
- `ui/features/vitals/blood_glucose_view_test.dart`: expected an “N more” row but found none.
- `ui/features/vitals/blood_pressure_view_test.dart`: expected the “N more” row and expansion flow; scrolling could not find the expected scrollable element.
- `ui/features/vitals/weight_view_test.dart`: expected an “N more” row; scrolling could not find the expected element.

These results were recorded without changing application code. The working tree already contained uncommitted application changes before verification; test execution did not authorize changing them.

## Test strategy visible in the repository

- Domain tests cover weight/dry-weight calculations and period helpers.
- Repository tests cover local CRUD, patient scoping, soft delete, and sign-out data wiping.
- DAO tests use in-memory SQLite and cover dirty rows, active filtering, and sync cursors.
- Sync tests cover serialization, cursor/conflict helpers, patient-ID reconciliation, and coordinator serialization.
- Widget tests cover vitals screens, forms, editing/deletion, charts, and navigation states.

Sync tests for multiple patients use an in-memory fake PostgREST (`app/test/helpers/fake_postgrest.dart`) to cover per-patient cursors, full pulls on new grants, eviction on revocation and viewer push suppression. SQL-level authorization is covered by the pgTAP suite above. There is no Flutter integration test against a running Supabase instance, no CI workflow, and no measured coverage report checked in.

The local Supabase config points its enabled seed step at `supabase/seed.sql`, but that file is absent from the repository. Treat local database reset/seed behavior as unverified until that configuration is corrected or the seed file is added.

## Local operation

Create a private `app/dart_defines/dev.json` from `app/dart_defines/dev.example.json` and provide `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` through `--dart-define-from-file`. Apply the migrations before attempting real sign-up/sync. The app shows a configuration error instead of starting the normal flow when either value is missing.

When offline, writes remain in the local database. Sync is attempted on startup/resume, after writes, after connectivity restoration and every 45 seconds while the app is in the foreground. A banner shows when the device is offline or the last run failed (with a Retry action); delivery is not guaranteed while the app is killed.

For Google sign-in setup see [Google sign-in](google-sign-in.md).
