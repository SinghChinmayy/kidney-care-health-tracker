import 'package:drift/drift.dart';

/// Device-local key/value settings scoped to the signed-in account
/// (wiped with the rest of the local DB on sign-out). Not synced.
@DataClassName('LocalSettingRow')
class LocalSettings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
