import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/mappers/fluid_intake_mapper.dart';
import 'package:app/data/local/tables/fluid_intake_logs.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:drift/drift.dart';

part 'fluid_intake_dao.g.dart';

@DriftAccessor(tables: [FluidIntakeLogs, Patients])
class FluidIntakeDao extends DatabaseAccessor<AppDatabase>
    with _$FluidIntakeDaoMixin {
  FluidIntakeDao(super.db);

  Future<List<FluidIntakeLog>> getActiveForPatient(String patientId) async {
    final rows = await (select(fluidIntakeLogs)
          ..where(
            (t) => t.patientId.equals(patientId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<FluidIntakeLog?> getLatestForPatient(String patientId) async {
    final rows = await (select(fluidIntakeLogs)
          ..where(
            (t) => t.patientId.equals(patientId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first.toDomain();
  }

  Future<List<FluidIntakeRow>> getDirtyRows() {
    return (select(fluidIntakeLogs)..where((t) => t.isDirty.equals(true)))
        .get();
  }

  Future<void> insertLog(FluidIntakeLog log, {required bool isDirty}) {
    return into(fluidIntakeLogs).insert(log.toCompanion(isDirty: isDirty));
  }

  Future<void> updateLog(FluidIntakeLog log, {required bool isDirty}) {
    return update(fluidIntakeLogs).replace(
      FluidIntakeRow(
        id: log.id,
        patientId: log.patientId ?? '',
        recordedAt: log.recordedAt,
        fluidMl: log.fluidMl,
        source: log.source,
        notes: log.notes,
        createdAt: log.createdAt ?? DateTime.now().toUtc(),
        updatedAt: log.updatedAt ?? DateTime.now().toUtc(),
        deletedAt: log.deletedAt,
        isDirty: isDirty,
      ),
    );
  }

  Future<void> softDelete(String id, DateTime deletedAt) {
    return (update(fluidIntakeLogs)..where((t) => t.id.equals(id))).write(
      FluidIntakeLogsCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        isDirty: const Value(true),
      ),
    );
  }

  Future<FluidIntakeRow?> getRowById(String id) {
    return (select(fluidIntakeLogs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertRemoteRow(FluidIntakeRow row, {required bool isDirty}) {
    return into(fluidIntakeLogs).insertOnConflictUpdate(
      FluidIntakeLogsCompanion(
        id: Value(row.id),
        patientId: Value(row.patientId),
        recordedAt: Value(row.recordedAt),
        fluidMl: Value(row.fluidMl),
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
    return (update(fluidIntakeLogs)..where((t) => t.id.equals(id))).write(
      FluidIntakeLogsCompanion(
        updatedAt: Value(updatedAt),
        isDirty: const Value(false),
      ),
    );
  }

  Future<void> reassignPatientId(String oldPatientId, String newPatientId) {
    return (update(fluidIntakeLogs)
          ..where((t) => t.patientId.equals(oldPatientId)))
        .write(FluidIntakeLogsCompanion(patientId: Value(newPatientId)));
  }
}
