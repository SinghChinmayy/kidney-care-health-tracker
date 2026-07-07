import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/mappers/blood_pressure_mapper.dart';
import 'package:app/data/local/tables/blood_pressure_readings.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:drift/drift.dart';

part 'blood_pressure_dao.g.dart';

@DriftAccessor(tables: [BloodPressureReadings, Patients])
class BloodPressureDao extends DatabaseAccessor<AppDatabase>
    with _$BloodPressureDaoMixin {
  BloodPressureDao(super.db);

  Future<List<BloodPressureReading>> getActiveForPatient(String patientId) async {
    final rows = await (select(bloodPressureReadings)
          ..where(
            (t) => t.patientId.equals(patientId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<BloodPressureReading?> getLatestForPatient(String patientId) async {
    final rows = await (select(bloodPressureReadings)
          ..where(
            (t) => t.patientId.equals(patientId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first.toDomain();
  }

  Future<List<BloodPressureRow>> getDirtyRows() {
    return (select(bloodPressureReadings)
          ..where((t) => t.isDirty.equals(true)))
        .get();
  }

  Future<void> insertReading(
    BloodPressureReading reading, {
    required bool isDirty,
  }) {
    return into(bloodPressureReadings)
        .insert(reading.toCompanion(isDirty: isDirty));
  }

  Future<void> updateReading(
    BloodPressureReading reading, {
    required bool isDirty,
  }) {
    return update(bloodPressureReadings).replace(
      BloodPressureRow(
        id: reading.id,
        patientId: reading.patientId ?? '',
        recordedAt: reading.recordedAt,
        systolic: reading.systolic,
        diastolic: reading.diastolic,
        heartRateBpm: reading.heartRateBpm,
        notes: reading.notes,
        createdAt: reading.createdAt ?? DateTime.now().toUtc(),
        updatedAt: reading.updatedAt ?? DateTime.now().toUtc(),
        deletedAt: reading.deletedAt,
        isDirty: isDirty,
      ),
    );
  }

  Future<void> softDelete(String id, DateTime deletedAt) {
    return (update(bloodPressureReadings)..where((t) => t.id.equals(id))).write(
      BloodPressureReadingsCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        isDirty: const Value(true),
      ),
    );
  }

  Future<BloodPressureRow?> getRowById(String id) {
    return (select(bloodPressureReadings)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertRemoteRow(BloodPressureRow row, {required bool isDirty}) {
    return into(bloodPressureReadings).insertOnConflictUpdate(
      BloodPressureReadingsCompanion(
        id: Value(row.id),
        patientId: Value(row.patientId),
        recordedAt: Value(row.recordedAt),
        systolic: Value(row.systolic),
        diastolic: Value(row.diastolic),
        heartRateBpm: Value(row.heartRateBpm),
        notes: Value(row.notes),
        createdAt: Value(row.createdAt),
        updatedAt: Value(row.updatedAt),
        deletedAt: Value(row.deletedAt),
        isDirty: Value(isDirty),
      ),
    );
  }

  Future<void> markSynced(String id, DateTime updatedAt) {
    return (update(bloodPressureReadings)..where((t) => t.id.equals(id))).write(
      BloodPressureReadingsCompanion(
        updatedAt: Value(updatedAt),
        isDirty: const Value(false),
      ),
    );
  }

  Future<void> reassignPatientId(String oldPatientId, String newPatientId) {
    return (update(bloodPressureReadings)
          ..where((t) => t.patientId.equals(oldPatientId)))
        .write(BloodPressureReadingsCompanion(patientId: Value(newPatientId)));
  }
}
