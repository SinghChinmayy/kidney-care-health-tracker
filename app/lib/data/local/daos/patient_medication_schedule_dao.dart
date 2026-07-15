import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/mappers/patient_medication_schedule_mapper.dart';
import 'package:app/data/local/tables/patient_medication_schedules.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:app/domain/models/patient_medication_schedule.dart';
import 'package:drift/drift.dart';

part 'patient_medication_schedule_dao.g.dart';

@DriftAccessor(tables: [PatientMedicationSchedules, Patients])
class PatientMedicationScheduleDao extends DatabaseAccessor<AppDatabase>
    with _$PatientMedicationScheduleDaoMixin {
  PatientMedicationScheduleDao(super.db);

  Future<PatientMedicationSchedule?> getActiveByPatientId(
    String patientId,
  ) async {
    final row = await (select(patientMedicationSchedules)
          ..where(
            (t) => t.patientId.equals(patientId) & t.deletedAt.isNull(),
          ))
        .getSingleOrNull();
    return row?.toDomain();
  }

  Future<List<PatientMedicationScheduleRow>> getDirtyRows() {
    return (select(patientMedicationSchedules)
          ..where((t) => t.isDirty.equals(true)))
        .get();
  }

  Future<PatientMedicationScheduleRow?> getRowById(String id) {
    return (select(patientMedicationSchedules)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<PatientMedicationScheduleRow?> getRowByPatientId(String patientId) {
    return (select(patientMedicationSchedules)
          ..where((t) => t.patientId.equals(patientId)))
        .getSingleOrNull();
  }

  Future<void> insertSchedule(
    PatientMedicationSchedule schedule, {
    required bool isDirty,
  }) {
    return into(patientMedicationSchedules).insert(
      schedule.toCompanion(isDirty: isDirty),
    );
  }

  Future<void> updateSchedule(
    PatientMedicationSchedule schedule, {
    required bool isDirty,
  }) {
    return update(patientMedicationSchedules).replace(
      PatientMedicationScheduleRow(
        id: schedule.id,
        patientId: schedule.patientId,
        schedule: schedule.byDay,
        createdAt: schedule.createdAt ?? DateTime.now().toUtc(),
        updatedAt: schedule.updatedAt ?? DateTime.now().toUtc(),
        deletedAt: schedule.deletedAt,
        isDirty: isDirty,
      ),
    );
  }

  Future<void> upsertRemoteRow(
    PatientMedicationScheduleRow row, {
    required bool isDirty,
  }) {
    return into(patientMedicationSchedules).insertOnConflictUpdate(
      PatientMedicationSchedulesCompanion(
        id: Value(row.id),
        patientId: Value(row.patientId),
        schedule: Value(row.schedule),
        createdAt: Value(row.createdAt),
        updatedAt: Value(row.updatedAt),
        deletedAt: Value(row.deletedAt),
        isDirty: Value(isDirty),
      ),
    );
  }

  Future<void> markSynced(String id, DateTime updatedAt) {
    return (update(patientMedicationSchedules)..where((t) => t.id.equals(id)))
        .write(
      PatientMedicationSchedulesCompanion(
        updatedAt: Value(updatedAt),
        isDirty: const Value(false),
      ),
    );
  }

  Future<void> deleteById(String id) {
    return (delete(patientMedicationSchedules)..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> reassignPatientId(String oldPatientId, String newPatientId) {
    return (update(patientMedicationSchedules)
          ..where((t) => t.patientId.equals(oldPatientId)))
        .write(
      PatientMedicationSchedulesCompanion(patientId: Value(newPatientId)),
    );
  }

  Future<void> rebindId({
    required String oldId,
    required String newId,
  }) async {
    if (oldId == newId) {
      return;
    }
    final row = await getRowById(oldId);
    if (row == null) {
      return;
    }
    await deleteById(oldId);
    await upsertRemoteRow(
      PatientMedicationScheduleRow(
        id: newId,
        patientId: row.patientId,
        schedule: row.schedule,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        isDirty: row.isDirty,
      ),
      isDirty: row.isDirty,
    );
  }
}
