// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_preferences_dao.dart';

// ignore_for_file: type=lint
mixin _$PatientPreferencesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PatientsTable get patients => attachedDatabase.patients;
  $PatientPrefsTable get patientPrefs => attachedDatabase.patientPrefs;
  PatientPreferencesDaoManager get managers =>
      PatientPreferencesDaoManager(this);
}

class PatientPreferencesDaoManager {
  final _$PatientPreferencesDaoMixin _db;
  PatientPreferencesDaoManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db.attachedDatabase, _db.patients);
  $$PatientPrefsTableTableManager get patientPrefs =>
      $$PatientPrefsTableTableManager(_db.attachedDatabase, _db.patientPrefs);
}
