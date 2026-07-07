import 'dart:developer' as developer;

import 'package:app/data/local/app_database.dart';
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
              BpSync(db: db, currentAuthUserId: currentAuthUserId),
              GlucoseSync(db: db, currentAuthUserId: currentAuthUserId),
              WeightSync(db: db, currentAuthUserId: currentAuthUserId),
            ];

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final List<SyncableTable> registry;

  Future<void> run() async {
    for (final table in registry) {
      try {
        await table.push(_supabase);
        await _db.syncStateDao.setLastSyncedRunAt(
          table.tableKey,
          DateTime.now().toUtc(),
        );
      } catch (error, stackTrace) {
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
        logSyncError('${table.tableKey} pull', error, stackTrace);
      }
    }
  }
}

void logSyncInfo(String message) {
  developer.log(message, name: 'SyncEngine');
}
