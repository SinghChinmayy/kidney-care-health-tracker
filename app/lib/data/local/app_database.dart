import 'package:app/data/local/converters/dialysis_days_of_week_converter.dart';
import 'package:app/data/local/converters/medication_schedule_converter.dart';
import 'package:app/data/local/daos/blood_glucose_dao.dart';
import 'package:app/data/local/daos/blood_pressure_dao.dart';
import 'package:app/data/local/daos/fluid_intake_dao.dart';
import 'package:app/data/local/daos/medications_dao.dart';
import 'package:app/data/local/daos/patient_access_dao.dart';
import 'package:app/data/local/daos/patient_medication_schedule_dao.dart';
import 'package:app/data/local/daos/patient_preferences_dao.dart';
import 'package:app/data/local/daos/patients_dao.dart';
import 'package:app/data/local/daos/sync_state_dao.dart';
import 'package:app/data/local/daos/weight_dao.dart';
import 'package:app/data/local/tables/blood_glucose_readings.dart';
import 'package:app/data/local/tables/blood_pressure_readings.dart';
import 'package:app/data/local/tables/fluid_intake_logs.dart';
import 'package:app/data/local/tables/local_settings.dart';
import 'package:app/data/local/tables/medications.dart';
import 'package:app/data/local/tables/patient_medication_schedules.dart';
import 'package:app/data/local/tables/patient_memberships.dart';
import 'package:app/data/local/tables/patient_preferences.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:app/data/local/tables/sync_state.dart';
import 'package:app/data/local/tables/weight_readings.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

export 'package:app/data/local/converters/dialysis_days_of_week_converter.dart';
export 'package:app/data/local/converters/medication_schedule_converter.dart';
export 'package:app/data/local/daos/blood_glucose_dao.dart';
export 'package:app/data/local/daos/blood_pressure_dao.dart';
export 'package:app/data/local/daos/fluid_intake_dao.dart';
export 'package:app/data/local/daos/medications_dao.dart';
export 'package:app/data/local/daos/patient_access_dao.dart';
export 'package:app/data/local/daos/patient_medication_schedule_dao.dart';
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
    PatientMedicationSchedules,
    PatientMemberships,
    LocalSettings,
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
    PatientMedicationScheduleDao,
    PatientAccessDao,
    SyncStateDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 10;

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
          if (from < 7) {
            await migrator.createTable(patientMedicationSchedules);
          }
          if (from < 8) {
            await migrator.addColumn(
              bloodPressureReadings,
              bloodPressureReadings.arm,
            );
            await migrator.addColumn(
              bloodPressureReadings,
              bloodPressureReadings.posture,
            );
            await migrator.addColumn(
              bloodPressureReadings,
              bloodPressureReadings.isDialysisDay,
            );
            await migrator.addColumn(
              bloodPressureReadings,
              bloodPressureReadings.dialysisPhase,
            );
          }
          if (from < 9) {
            await migrator.addColumn(patients, patients.bloodGroup);
            await migrator.addColumn(
              bloodPressureReadings,
              bloodPressureReadings.recordedBy,
            );
            await migrator.addColumn(
              bloodGlucoseReadings,
              bloodGlucoseReadings.recordedBy,
            );
            await migrator.addColumn(
              weightReadings,
              weightReadings.recordedBy,
            );
            await migrator.addColumn(
              fluidIntakeLogs,
              fluidIntakeLogs.recordedBy,
            );
          }
          if (from < 10) {
            // Multi-patient (s2.3): auth_user_id becomes nullable, which
            // SQLite can only do by rebuilding the table. Foreign keys are
            // not enforced on this connection, so child rows are untouched.
            await migrator.alterTable(TableMigration(patients));
            await migrator.createTable(patientMemberships);
            await migrator.createTable(localSettings);
            // Pull cursors become per patient ('table:patientId'); drop the
            // old per-table cursors so every patient gets one full pull.
            await delete(syncState).go();
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
      await delete(patientMedicationSchedules).go();
      await delete(patientPrefs).go();
      await delete(patients).go();
      await delete(patientMemberships).go();
      await delete(localSettings).go();
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
      await patientMedicationScheduleDao.reassignPatientId(
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
          bloodGroup: localRow.bloodGroup,
          createdAt: localRow.createdAt,
          updatedAt: localRow.updatedAt,
          deletedAt: localRow.deletedAt,
          isDirty: localRow.isDirty,
        ),
        isDirty: localRow.isDirty,
      );
    });
  }

  /// Removes every cached row for [patientId] (revoked access, or a
  /// read-only patient whose unsynced local edits must be discarded).
  ///
  /// With [keepMembership] the patient stays in scope so the next pull
  /// restores a clean server copy.
  Future<void> evictPatient(
    String patientId, {
    bool keepMembership = false,
  }) async {
    await transaction(() async {
      await (delete(bloodPressureReadings)
            ..where((t) => t.patientId.equals(patientId)))
          .go();
      await (delete(bloodGlucoseReadings)
            ..where((t) => t.patientId.equals(patientId)))
          .go();
      await (delete(weightReadings)
            ..where((t) => t.patientId.equals(patientId)))
          .go();
      await (delete(fluidIntakeLogs)
            ..where((t) => t.patientId.equals(patientId)))
          .go();
      await (delete(patientPrefs)..where((t) => t.patientId.equals(patientId)))
          .go();
      await (delete(patientMedicationSchedules)
            ..where((t) => t.patientId.equals(patientId)))
          .go();
      await (delete(patients)..where((t) => t.id.equals(patientId))).go();
      await (delete(syncState)
            ..where((t) => t.tableKey.like('%:$patientId')))
          .go();
      if (!keepMembership) {
        await patientAccessDao.deleteMembership(patientId);
        final active =
            await patientAccessDao.getSetting(activePatientSettingKey);
        if (active == patientId) {
          await patientAccessDao.setSetting(activePatientSettingKey, null);
        }
      }
    });
  }

  /// True when [patientId] has local rows waiting to be pushed.
  Future<bool> hasDirtyRowsForPatient(String patientId) async {
    final row = await customSelect(
      'SELECT 1 FROM ('
      ' SELECT patient_id FROM blood_pressure_readings WHERE is_dirty = 1'
      ' UNION ALL SELECT patient_id FROM blood_glucose_readings WHERE is_dirty = 1'
      ' UNION ALL SELECT patient_id FROM weight_readings WHERE is_dirty = 1'
      ' UNION ALL SELECT patient_id FROM fluid_intake_logs WHERE is_dirty = 1'
      ' UNION ALL SELECT patient_id FROM patient_prefs WHERE is_dirty = 1'
      ' UNION ALL SELECT patient_id FROM patient_medication_schedules WHERE is_dirty = 1'
      ' UNION ALL SELECT id AS patient_id FROM patients WHERE is_dirty = 1'
      ') WHERE patient_id = ? LIMIT 1',
      variables: [Variable.withString(patientId)],
    ).getSingleOrNull();
    return row != null;
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
