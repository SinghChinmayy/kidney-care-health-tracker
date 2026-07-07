import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/mappers/blood_glucose_mapper.dart';
import 'package:app/data/local/tables/blood_glucose_readings.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:drift/drift.dart';

part 'blood_glucose_dao.g.dart';

@DriftAccessor(tables: [BloodGlucoseReadings, Patients])
class BloodGlucoseDao extends DatabaseAccessor<AppDatabase>
    with _$BloodGlucoseDaoMixin {
  BloodGlucoseDao(super.db);

  Future<List<BloodGlucoseReading>> getActiveForPatient(
    String patientId,
  ) async {
    final rows = await (select(bloodGlucoseReadings)
          ..where(
            (t) => t.patientId.equals(patientId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<BloodGlucoseReading?> getLatestForPatient(String patientId) async {
    final rows = await (select(bloodGlucoseReadings)
          ..where(
            (t) => t.patientId.equals(patientId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first.toDomain();
  }

  Future<List<BloodGlucoseRow>> getDirtyRows() {
    return (select(bloodGlucoseReadings)
          ..where((t) => t.isDirty.equals(true)))
        .get();
  }

  Future<void> insertReading(
    BloodGlucoseReading reading, {
    required bool isDirty,
  }) {
    return into(bloodGlucoseReadings)
        .insert(reading.toCompanion(isDirty: isDirty));
  }

  Future<void> updateReading(
    BloodGlucoseReading reading, {
    required bool isDirty,
  }) {
    return update(bloodGlucoseReadings).replace(
      BloodGlucoseRow(
        id: reading.id,
        patientId: reading.patientId ?? '',
        recordedAt: reading.recordedAt,
        valueMgDl: reading.valueMgDl,
        context: reading.context,
        source: reading.source,
        notes: reading.notes,
        createdAt: reading.createdAt ?? DateTime.now().toUtc(),
        updatedAt: reading.updatedAt ?? DateTime.now().toUtc(),
        deletedAt: reading.deletedAt,
        isDirty: isDirty,
      ),
    );
  }

  Future<void> softDelete(String id, DateTime deletedAt) {
    return (update(bloodGlucoseReadings)..where((t) => t.id.equals(id))).write(
      BloodGlucoseReadingsCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        isDirty: const Value(true),
      ),
    );
  }

  Future<BloodGlucoseRow?> getRowById(String id) {
    return (select(bloodGlucoseReadings)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertRemoteRow(BloodGlucoseRow row, {required bool isDirty}) {
    return into(bloodGlucoseReadings).insertOnConflictUpdate(
      BloodGlucoseReadingsCompanion(
        id: Value(row.id),
        patientId: Value(row.patientId),
        recordedAt: Value(row.recordedAt),
        valueMgDl: Value(row.valueMgDl),
        context: Value(row.context),
        source: Value(row.source),
        notes: Value(row.notes),
        createdAt: Value(row.createdAt),
        updatedAt: Value(row.updatedAt),
        deletedAt: Value(row.deletedAt),
        isDirty: Value(isDirty),
      ),
    );
  }

  Future<void> markSynced(String id, DateTime updatedAt) {
    return (update(bloodGlucoseReadings)..where((t) => t.id.equals(id))).write(
      BloodGlucoseReadingsCompanion(
        updatedAt: Value(updatedAt),
        isDirty: const Value(false),
      ),
    );
  }

  Future<void> reassignPatientId(String oldPatientId, String newPatientId) {
    return (update(bloodGlucoseReadings)
          ..where((t) => t.patientId.equals(oldPatientId)))
        .write(BloodGlucoseReadingsCompanion(patientId: Value(newPatientId)));
  }
}
