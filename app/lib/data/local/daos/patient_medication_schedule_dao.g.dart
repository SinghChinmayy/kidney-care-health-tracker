// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_medication_schedule_dao.dart';

// ignore_for_file: type=lint
mixin _$PatientMedicationScheduleDaoMixin on DatabaseAccessor<AppDatabase> {
  $PatientsTable get patients => attachedDatabase.patients;
  $PatientMedicationSchedulesTable get patientMedicationSchedules =>
      attachedDatabase.patientMedicationSchedules;
  PatientMedicationScheduleDaoManager get managers =>
      PatientMedicationScheduleDaoManager(this);
}

class PatientMedicationScheduleDaoManager {
  final _$PatientMedicationScheduleDaoMixin _db;
  PatientMedicationScheduleDaoManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db.attachedDatabase, _db.patients);
  $$PatientMedicationSchedulesTableTableManager
  get patientMedicationSchedules =>
      $$PatientMedicationSchedulesTableTableManager(
        _db.attachedDatabase,
        _db.patientMedicationSchedules,
      );
}
