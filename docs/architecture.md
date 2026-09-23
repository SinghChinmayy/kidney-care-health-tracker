# Architecture

This document describes the implementation currently present in `app/lib`, not the broader product plan.

## Layers

- `ui/`: Flutter screens and `ChangeNotifier` view models. View models call repositories and expose loading/error/data state to widgets.
- `domain/models/`: immutable-ish application models for patients, readings, preferences, medications, and schedules.
- `data/repositories/`: application-facing operations. Repositories resolve the signed-in patient, write locally first, and notify `SyncCoordinator` after mutations.
- `data/local/`: Drift database, tables, DAOs, mappers, converters, generated query code, and schema migrations. `AppDatabase.schemaVersion` is currently 7.
- `data/sync/`: a `SyncableTable` registry, table-specific mappers, push/pull operations, cursors, and a debounced coordinator.
- `data/services/`: Supabase Auth wrapper and a lightweight connectivity probe.

`app/lib/app.dart` wires the graph with `provider`. `main.dart` validates build-time Supabase configuration, initializes Supabase, opens the Drift database, and mounts the app.

## Runtime flow

1. `AuthGate` listens to Supabase auth state and selects the login screen or signed-in shell.
2. `InitialSyncGate` checks connectivity and runs an initial synchronization before showing signed-in content.
3. A form validates input in the UI, then calls a view model and repository.
4. The repository writes to Drift, sets `is_dirty`, and schedules a debounced sync.
5. `SyncEngine` processes registered tables in push-then-pull order. Each table failure is logged independently so one table does not stop the rest of the run.
6. Pulls use a per-table `last_pulled_at` cursor. Remote rows are applied only when their `updated_at` is newer than the local row; equal timestamps keep the local row.

## Reliability and concurrency decisions

- Local-first writes avoid making a health log depend on immediate network availability.
- Dirty flags and soft deletes preserve unsynchronized changes across retries and app updates.
- `SyncCoordinator` serializes runs. If a write/resume occurs while a run is active, it records one pending follow-up run instead of overlapping the engine.
- A two-second debounce coalesces rapid local writes.
- Server-side `updated_at` triggers avoid trusting device clocks for conflict ordering.
- Patient bootstrap can create a server patient ID before onboarding; sync reconciles local foreign keys when the server row is discovered.

## Boundaries and gaps

The current sync registry covers seven remote tables. The local medication catalog is seeded locally and is not in the sync registry. Sync is foreground-only, errors are developer logs rather than user-visible status, and there is no background worker or durable retry schedule. These are explicit gaps, not hidden production capabilities.
