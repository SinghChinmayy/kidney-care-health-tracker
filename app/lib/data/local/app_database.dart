import 'package:app/data/local/converters/dialysis_days_of_week_converter.dart';
import 'package:app/data/local/daos/blood_glucose_dao.dart';
import 'package:app/data/local/daos/blood_pressure_dao.dart';
import 'package:app/data/local/daos/fluid_intake_dao.dart';
import 'package:app/data/local/daos/medications_dao.dart';
import 'package:app/data/local/daos/patient_preferences_dao.dart';
import 'package:app/data/local/daos/patients_dao.dart';
import 'package:app/data/local/daos/sync_state_dao.dart';
import 'package:app/data/local/daos/weight_dao.dart';
import 'package:app/data/local/tables/blood_glucose_readings.dart';
import 'package:app/data/local/tables/blood_pressure_readings.dart';
import 'package:app/data/local/tables/fluid_intake_logs.dart';
import 'package:app/data/local/tables/medications.dart';
import 'package:app/data/local/tables/patient_preferences.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:app/data/local/tables/sync_state.dart';
import 'package:app/data/local/tables/weight_readings.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

export 'package:app/data/local/converters/dialysis_days_of_week_converter.dart';
export 'package:app/data/local/daos/blood_glucose_dao.dart';
export 'package:app/data/local/daos/blood_pressure_dao.dart';
export 'package:app/data/local/daos/fluid_intake_dao.dart';
export 'package:app/data/local/daos/medications_dao.dart';
export 'package:app/data/local/daos/patient_preferences_dao.dart';
export 'package:app/data/local/daos/patients_dao.dart';
export 'package:app/data/local/daos/sync_state_dao.dart';
export 'package:app/data/local/daos/weight_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Patients,
    PatientPrefs,
    BloodPressureReadings,
    BloodGlucoseReadings,
    WeightReadings,
    FluidIntakeLogs,
    Medications,
    SyncState,
  ],
  daos: [
    PatientsDao,
    PatientPreferencesDao,
    BloodPressureDao,
    BloodGlucoseDao,
    WeightDao,
    FluidIntakeDao,
    MedicationsDao,
    SyncStateDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(
              weightReadings,
              weightReadings.dialysisTiming,
            );
            await migrator.addColumn(
              weightReadings,
              weightReadings.weightContext,
            );
            await customStatement(
              "UPDATE weight_readings SET dialysis_timing = 'non_dialysis' "
              "WHERE dialysis_timing IS NULL",
            );
          }
          if (from < 3) {
            await migrator.createTable(fluidIntakeLogs);
          }
          if (from < 4) {
            await migrator.createTable(patientPrefs);
          }
          if (from < 5) {
            await migrator.addColumn(
              patients,
              patients.dialysisDaysOfWeek,
            );
          }
          if (from < 6) {
            await migrator.createTable(medications);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'kidney_care');
  }

  Future<void> wipeAllData() async {
    await transaction(() async {
      await delete(bloodPressureReadings).go();
      await delete(bloodGlucoseReadings).go();
      await delete(weightReadings).go();
      await delete(fluidIntakeLogs).go();
      await delete(medications).go();
      await delete(patientPrefs).go();
      await delete(patients).go();
      await delete(syncState).go();
    });
  }

  /// Rewrites local FK references when the server patient id differs from local seed.
  Future<void> reconcilePatientId({
    required String oldPatientId,
    required String newPatientId,
  }) async {
    if (oldPatientId == newPatientId) {
      return;
    }

    await transaction(() async {
      await bloodPressureDao.reassignPatientId(oldPatientId, newPatientId);
      await bloodGlucoseDao.reassignPatientId(oldPatientId, newPatientId);
      await weightDao.reassignPatientId(oldPatientId, newPatientId);
      await fluidIntakeDao.reassignPatientId(oldPatientId, newPatientId);
      await patientPreferencesDao.reassignPatientId(
        oldPatientId,
        newPatientId,
      );

      final localRow = await patientsDao.getRowById(oldPatientId);
      if (localRow == null) {
        return;
      }

      await delete(patients).delete(localRow);
      await patientsDao.upsertRemoteRow(
        PatientRow(
          id: newPatientId,
          authUserId: localRow.authUserId,
          firstName: localRow.firstName,
          lastName: localRow.lastName,
          dateOfBirth: localRow.dateOfBirth,
          sex: localRow.sex,
          ckdStage: localRow.ckdStage,
          dialysisType: localRow.dialysisType,
          dialysisDaysOfWeek: localRow.dialysisDaysOfWeek,
          heightCm: localRow.heightCm,
          createdAt: localRow.createdAt,
          updatedAt: localRow.updatedAt,
          deletedAt: localRow.deletedAt,
          isDirty: localRow.isDirty,
        ),
        isDirty: localRow.isDirty,
      );
    });
  }

  Future<String?> patientIdForAuthUser(String authUserId) async {
    final row = await patientsDao.getRowByAuthUserId(authUserId);
    return row?.id;
  }

  Future<bool> hasLocalDataForAuthUser(String authUserId) async {
    final row = await patientsDao.getRowByAuthUserId(authUserId);
    return row != null;
  }
}
