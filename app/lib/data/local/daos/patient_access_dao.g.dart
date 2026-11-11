// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_access_dao.dart';

// ignore_for_file: type=lint
mixin _$PatientAccessDaoMixin on DatabaseAccessor<AppDatabase> {
  $PatientMembershipsTable get patientMemberships =>
      attachedDatabase.patientMemberships;
  $LocalSettingsTable get localSettings => attachedDatabase.localSettings;
  PatientAccessDaoManager get managers => PatientAccessDaoManager(this);
}

class PatientAccessDaoManager {
  final _$PatientAccessDaoMixin _db;
  PatientAccessDaoManager(this._db);
  $$PatientMembershipsTableTableManager get patientMemberships =>
      $$PatientMembershipsTableTableManager(
        _db.attachedDatabase,
        _db.patientMemberships,
      );
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db.attachedDatabase, _db.localSettings);
}
