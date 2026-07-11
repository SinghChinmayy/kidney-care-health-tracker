import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/mappers/patient_mapper.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:app/domain/models/patient.dart';
import 'package:drift/drift.dart';

part 'patients_dao.g.dart';

@DriftAccessor(tables: [Patients])
class PatientsDao extends DatabaseAccessor<AppDatabase>
    with _$PatientsDaoMixin {
  PatientsDao(super.db);

  Future<Patient?> getActiveByAuthUserId(String authUserId) async {
    final row = await (select(patients)
          ..where(
            (t) => t.authUserId.equals(authUserId) & t.deletedAt.isNull(),
          ))
        .getSingleOrNull();
    return row?.toDomain();
  }

  Future<Patient?> getActiveById(String id) async {
    final row = await (select(patients)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row?.toDomain();
  }

  Future<List<PatientRow>> getDirtyRows() {
    return (select(patients)..where((t) => t.isDirty.equals(true))).get();
  }

  Future<bool> hasAnyData() async {
    final row = await select(patients).getSingleOrNull();
    return row != null;
  }

  Future<void> insertPatient(Patient patient, {required bool isDirty}) {
    return into(patients).insert(patient.toCompanion(isDirty: isDirty));
  }

  Future<void> updatePatient(Patient patient, {required bool isDirty}) {
    return update(patients).replace(
      PatientRow(
        id: patient.id,
        authUserId: patient.authUserId,
        firstName: patient.firstName,
        lastName: patient.lastName,
        dateOfBirth: patient.dateOfBirth,
        sex: patient.sex,
        ckdStage: patient.ckdStage,
        dialysisType: patient.dialysisType,
        dialysisDaysOfWeek: patient.dialysisDaysOfWeek,
        heightCm: patient.heightCm,
        createdAt: patient.createdAt ?? DateTime.now().toUtc(),
        updatedAt: patient.updatedAt ?? DateTime.now().toUtc(),
        deletedAt: patient.deletedAt,
        isDirty: isDirty,
      ),
    );
  }

  Future<void> softDelete(String id, DateTime deletedAt) {
    return (update(patients)..where((t) => t.id.equals(id))).write(
      PatientsCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        isDirty: const Value(true),
      ),
    );
  }

  Future<PatientRow?> getRowById(String id) {
    return (select(patients)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<PatientRow?> getRowByAuthUserId(String authUserId) {
    return (select(patients)
          ..where((t) => t.authUserId.equals(authUserId)))
        .getSingleOrNull();
  }

  Future<void> upsertRemoteRow(PatientRow row, {required bool isDirty}) {
    return into(patients).insertOnConflictUpdate(
      PatientsCompanion(
        id: Value(row.id),
        authUserId: Value(row.authUserId),
        firstName: Value(row.firstName),
        lastName: Value(row.lastName),
        dateOfBirth: Value(row.dateOfBirth),
        sex: Value(row.sex),
        ckdStage: Value(row.ckdStage),
        dialysisType: Value(row.dialysisType),
        dialysisDaysOfWeek: Value(row.dialysisDaysOfWeek),
        heightCm: Value(row.heightCm),
        createdAt: Value(row.createdAt),
        updatedAt: Value(row.updatedAt),
        deletedAt: Value(row.deletedAt),
        isDirty: Value(isDirty),
      ),
    );
  }

  Future<void> markSynced(String id, DateTime updatedAt) {
    return (update(patients)..where((t) => t.id.equals(id))).write(
      PatientsCompanion(
        updatedAt: Value(updatedAt),
        isDirty: const Value(false),
      ),
    );
  }
}
