// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fluid_intake_dao.dart';

// ignore_for_file: type=lint
mixin _$FluidIntakeDaoMixin on DatabaseAccessor<AppDatabase> {
  $PatientsTable get patients => attachedDatabase.patients;
  $FluidIntakeLogsTable get fluidIntakeLogs => attachedDatabase.fluidIntakeLogs;
  FluidIntakeDaoManager get managers => FluidIntakeDaoManager(this);
}

class FluidIntakeDaoManager {
  final _$FluidIntakeDaoMixin _db;
  FluidIntakeDaoManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db.attachedDatabase, _db.patients);
  $$FluidIntakeLogsTableTableManager get fluidIntakeLogs =>
      $$FluidIntakeLogsTableTableManager(
        _db.attachedDatabase,
        _db.fluidIntakeLogs,
      );
}
