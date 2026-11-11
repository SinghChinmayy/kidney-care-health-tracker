import 'dart:developer' as developer;

import 'package:app/data/local/app_database.dart';
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
  })  : _db = db,
        _supabase = supabase,
        registry = registry ??
            [
              PatientsSync(db: db, currentAuthUserId: currentAuthUserId),
              PatientPreferencesSync(
                db: db,
                currentAuthUserId: currentAuthUserId,
              ),
              BpSync(db: db, currentAuthUserId: currentAuthUserId),
              GlucoseSync(db: db, currentAuthUserId: currentAuthUserId),
              WeightSync(db: db, currentAuthUserId: currentAuthUserId),
              FluidIntakeSync(db: db, currentAuthUserId: currentAuthUserId),
              PatientMedicationScheduleSync(
                db: db,
                currentAuthUserId: currentAuthUserId,
              ),
            ];

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final List<SyncableTable> registry;

  /// Pushes then pulls every registered table. Failures are isolated per
  /// table (one bad table never blocks the rest) and reported back so the
  /// coordinator can surface them.
  Future<SyncRunResult> run() async {
    final failed = <String>{};
    for (final table in registry) {
      try {
        await table.push(_supabase);
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
        await table.pull(_supabase);
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
}

void logSyncInfo(String message) {
  developer.log(message, name: 'SyncEngine');
}
