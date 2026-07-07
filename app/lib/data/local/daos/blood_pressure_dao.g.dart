// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blood_pressure_dao.dart';

// ignore_for_file: type=lint
mixin _$BloodPressureDaoMixin on DatabaseAccessor<AppDatabase> {
  $PatientsTable get patients => attachedDatabase.patients;
  $BloodPressureReadingsTable get bloodPressureReadings =>
      attachedDatabase.bloodPressureReadings;
  BloodPressureDaoManager get managers => BloodPressureDaoManager(this);
}

class BloodPressureDaoManager {
  final _$BloodPressureDaoMixin _db;
  BloodPressureDaoManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db.attachedDatabase, _db.patients);
  $$BloodPressureReadingsTableTableManager get bloodPressureReadings =>
      $$BloodPressureReadingsTableTableManager(
        _db.attachedDatabase,
        _db.bloodPressureReadings,
      );
}
