import 'dart:developer' as developer;

import 'package:app/data/local/app_database.dart';
import 'package:app/data/sync/patient_access_sync.dart';
import 'package:app/data/sync/sync_status.dart';
import 'package:app/data/sync/syncable_table.dart';
import 'package:app/data/sync/tables/sync_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required SupabaseClient supabase,
    required String? Function() currentAuthUserId,
    List<SyncableTable>? registry,
    PatientAccessSync? accessSync,
    void Function()? onAccessChanged,
  })  : _db = db,
        _supabase = supabase,
        _currentAuthUserId = currentAuthUserId,
        _accessSync = accessSync ?? PatientAccessSync(db: db),
        _onAccessChanged = onAccessChanged,
        registry = registry ??
            [
              PatientsSync(db: db),
              PatientPreferencesSync(db: db),
              bloodPressureSync(db),
              bloodGlucoseSync(db),
              weightSync(db),
              fluidIntakeSync(db),
              PatientMedicationScheduleSync(db: db),
            ];

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final String? Function() _currentAuthUserId;
  final PatientAccessSync _accessSync;
  final void Function()? _onAccessChanged;
  final List<SyncableTable> registry;

  /// Refreshes access, then pushes and pulls every registered table for
  /// every accessible patient. Failures are isolated per table (one bad
  /// table never blocks the rest) and reported back to the coordinator.
  Future<SyncRunResult> run() async {
    final failed = <String>{};
    final scope = await _resolveScope(failed);

    for (final table in registry) {
      try {
        await table.push(_supabase, scope);
        await _db.syncStateDao.setLastSyncedRunAt(
          table.tableKey,
          DateTime.now().toUtc(),
        );
      } catch (error, stackTrace) {
        failed.add(table.tableKey);
        logSyncError('${table.tableKey} push', error, stackTrace);
      }
    }

    for (final table in registry) {
      try {
        await table.pull(_supabase, scope);
        await _db.syncStateDao.setLastSyncedRunAt(
          table.tableKey,
          DateTime.now().toUtc(),
        );
      } catch (error, stackTrace) {
        failed.add(table.tableKey);
        logSyncError('${table.tableKey} pull', error, stackTrace);
      }
    }

    return SyncRunResult(failedTables: failed.toList());
  }

  Future<SyncScope> _resolveScope(Set<String> failed) async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return SyncScope.empty;
    }
    try {
      final result = await _accessSync.refresh(_supabase, authUserId);
      if (result.changed) {
        _onAccessChanged?.call();
      }
      return result.scope;
    } catch (error, stackTrace) {
      failed.add(PatientAccessSync.remoteTableName);
      logSyncError('${PatientAccessSync.remoteTableName} refresh', error,
          stackTrace);
      return _accessSync.localScope(authUserId);
    }
  }
}

void logSyncInfo(String message) {
  developer.log(message, name: 'SyncEngine');
}
