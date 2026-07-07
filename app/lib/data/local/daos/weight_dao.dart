import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/mappers/weight_mapper.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:app/data/local/tables/weight_readings.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:drift/drift.dart';

part 'weight_dao.g.dart';

@DriftAccessor(tables: [WeightReadings, Patients])
class WeightDao extends DatabaseAccessor<AppDatabase> with _$WeightDaoMixin {
  WeightDao(super.db);

  Future<List<WeightReading>> getActiveForPatient(String patientId) async {
    final rows = await (select(weightReadings)
          ..where(
            (t) => t.patientId.equals(patientId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<WeightReading?> getLatestForPatient(String patientId) async {
    final rows = await (select(weightReadings)
          ..where(
            (t) => t.patientId.equals(patientId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first.toDomain();
  }

  Future<List<WeightRow>> getDirtyRows() {
    return (select(weightReadings)..where((t) => t.isDirty.equals(true))).get();
  }

  Future<void> insertReading(WeightReading reading, {required bool isDirty}) {
    return into(weightReadings).insert(reading.toCompanion(isDirty: isDirty));
  }

  Future<void> updateReading(WeightReading reading, {required bool isDirty}) {
    return update(weightReadings).replace(
      WeightRow(
        id: reading.id,
        patientId: reading.patientId ?? '',
        recordedAt: reading.recordedAt,
        valueKg: reading.valueKg,
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
    return (update(weightReadings)..where((t) => t.id.equals(id))).write(
      WeightReadingsCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        isDirty: const Value(true),
      ),
    );
  }
}
