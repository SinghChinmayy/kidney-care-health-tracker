// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blood_glucose_dao.dart';

// ignore_for_file: type=lint
mixin _$BloodGlucoseDaoMixin on DatabaseAccessor<AppDatabase> {
  $PatientsTable get patients => attachedDatabase.patients;
  $BloodGlucoseReadingsTable get bloodGlucoseReadings =>
      attachedDatabase.bloodGlucoseReadings;
  BloodGlucoseDaoManager get managers => BloodGlucoseDaoManager(this);
}

class BloodGlucoseDaoManager {
  final _$BloodGlucoseDaoMixin _db;
  BloodGlucoseDaoManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db.attachedDatabase, _db.patients);
  $$BloodGlucoseReadingsTableTableManager get bloodGlucoseReadings =>
      $$BloodGlucoseReadingsTableTableManager(
        _db.attachedDatabase,
        _db.bloodGlucoseReadings,
      );
}
