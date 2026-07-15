import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/patient_medication_schedule.dart';
import 'package:drift/drift.dart';

extension PatientMedicationScheduleRowMapper on PatientMedicationScheduleRow {
  PatientMedicationSchedule toDomain() {
    return PatientMedicationSchedule(
      id: id,
      patientId: patientId,
      byDay: schedule,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension PatientMedicationScheduleDomainMapper on PatientMedicationSchedule {
  PatientMedicationSchedulesCompanion toCompanion({required bool isDirty}) {
    final now = DateTime.now().toUtc();
    return PatientMedicationSchedulesCompanion.insert(
      id: id,
      patientId: patientId,
      schedule: Value(byDay),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }
}
