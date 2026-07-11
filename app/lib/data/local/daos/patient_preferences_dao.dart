import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/mappers/patient_preferences_mapper.dart';
import 'package:app/data/local/tables/patient_preferences.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:app/domain/models/patient_preferences.dart';
import 'package:drift/drift.dart';

part 'patient_preferences_dao.g.dart';

@DriftAccessor(tables: [PatientPrefs, Patients])
class PatientPreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PatientPreferencesDaoMixin {
  PatientPreferencesDao(super.db);

  Future<PatientPreferences?> getActiveByPatientId(String patientId) async {
    final row = await (select(patientPrefs)
          ..where(
            (t) => t.patientId.equals(patientId) & t.deletedAt.isNull(),
          ))
        .getSingleOrNull();
    return row?.toDomain();
  }

  Future<List<PatientPreferencesRow>> getDirtyRows() {
    return (select(patientPrefs)..where((t) => t.isDirty.equals(true))).get();
  }

  Future<PatientPreferencesRow?> getRowById(String id) {
    return (select(patientPrefs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<PatientPreferencesRow?> getRowByPatientId(String patientId) {
    return (select(patientPrefs)..where((t) => t.patientId.equals(patientId)))
        .getSingleOrNull();
  }

  Future<void> insertPreferences(
    PatientPreferences preferences, {
    required bool isDirty,
  }) {
    return into(patientPrefs).insert(
      preferences.toCompanion(isDirty: isDirty),
    );
  }

  Future<void> updatePreferences(
    PatientPreferences preferences, {
    required bool isDirty,
  }) {
    return update(patientPrefs).replace(
      PatientPreferencesRow(
        id: preferences.id,
        patientId: preferences.patientId,
        weightUnit: preferences.weightUnit,
        bloodGlucoseUnit: preferences.bloodGlucoseUnit,
        dailyWaterGoalMl: preferences.dailyWaterGoalMl,
        createdAt: preferences.createdAt ?? DateTime.now().toUtc(),
        updatedAt: preferences.updatedAt ?? DateTime.now().toUtc(),
        deletedAt: preferences.deletedAt,
        isDirty: isDirty,
      ),
    );
  }

  Future<void> upsertRemoteRow(
    PatientPreferencesRow row, {
    required bool isDirty,
  }) {
    return into(patientPrefs).insertOnConflictUpdate(
      PatientPrefsCompanion(
        id: Value(row.id),
        patientId: Value(row.patientId),
        weightUnit: Value(row.weightUnit),
        bloodGlucoseUnit: Value(row.bloodGlucoseUnit),
        dailyWaterGoalMl: Value(row.dailyWaterGoalMl),
        createdAt: Value(row.createdAt),
        updatedAt: Value(row.updatedAt),
        deletedAt: Value(row.deletedAt),
        isDirty: Value(isDirty),
      ),
    );
  }

  Future<void> markSynced(String id, DateTime updatedAt) {
    return (update(patientPrefs)..where((t) => t.id.equals(id))).write(
      PatientPrefsCompanion(
        updatedAt: Value(updatedAt),
        isDirty: const Value(false),
      ),
    );
  }

  Future<void> deleteById(String id) {
    return (delete(patientPrefs)..where((t) => t.id.equals(id))).go();
  }

  Future<void> reassignPatientId(String oldPatientId, String newPatientId) {
    return (update(patientPrefs)
          ..where((t) => t.patientId.equals(oldPatientId)))
        .write(PatientPrefsCompanion(patientId: Value(newPatientId)));
  }

  /// Rewrites local primary key to match the remote bootstrap row.
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
      PatientPreferencesRow(
        id: newId,
        patientId: row.patientId,
        weightUnit: row.weightUnit,
        bloodGlucoseUnit: row.bloodGlucoseUnit,
        dailyWaterGoalMl: row.dailyWaterGoalMl,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        isDirty: row.isDirty,
      ),
      isDirty: row.isDirty,
    );
  }
}
