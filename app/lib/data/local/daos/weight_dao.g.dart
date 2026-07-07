// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_dao.dart';

// ignore_for_file: type=lint
mixin _$WeightDaoMixin on DatabaseAccessor<AppDatabase> {
  $PatientsTable get patients => attachedDatabase.patients;
  $WeightReadingsTable get weightReadings => attachedDatabase.weightReadings;
  WeightDaoManager get managers => WeightDaoManager(this);
}

class WeightDaoManager {
  final _$WeightDaoMixin _db;
  WeightDaoManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db.attachedDatabase, _db.patients);
  $$WeightReadingsTableTableManager get weightReadings =>
      $$WeightReadingsTableTableManager(
        _db.attachedDatabase,
        _db.weightReadings,
      );
}
