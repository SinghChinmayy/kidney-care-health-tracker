import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/tables/sync_state.dart';
import 'package:drift/drift.dart';

part 'sync_state_dao.g.dart';

@DriftAccessor(tables: [SyncState])
class SyncStateDao extends DatabaseAccessor<AppDatabase>
    with _$SyncStateDaoMixin {
  SyncStateDao(super.db);

  Future<DateTime?> getLastPulledAt(String tableKey) async {
    final row = await (select(syncState)
          ..where((t) => t.tableKey.equals(tableKey)))
        .getSingleOrNull();
    return row?.lastPulledAt;
  }

  Future<void> setLastPulledAt(String tableKey, DateTime? lastPulledAt) {
    return into(syncState).insertOnConflictUpdate(
      SyncStateCompanion.insert(
        tableKey: tableKey,
        lastPulledAt: Value(lastPulledAt),
      ),
    );
  }

  Future<void> setLastSyncedRunAt(String tableKey, DateTime lastSyncedRunAt) {
    return into(syncState).insertOnConflictUpdate(
      SyncStateCompanion.insert(
        tableKey: tableKey,
        lastSyncedRunAt: Value(lastSyncedRunAt),
      ),
    );
  }
}
