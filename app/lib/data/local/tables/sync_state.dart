import 'package:drift/drift.dart';

@DataClassName('SyncStateRow')
class SyncState extends Table {
  TextColumn get tableKey => text()();

  DateTimeColumn get lastPulledAt => dateTime().nullable()();

  DateTimeColumn get lastSyncedRunAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {tableKey};
}
