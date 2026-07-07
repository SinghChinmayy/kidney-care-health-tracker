import 'package:app/data/local/daos/blood_glucose_dao.dart';
import 'package:app/data/local/daos/blood_pressure_dao.dart';
import 'package:app/data/local/daos/patients_dao.dart';
import 'package:app/data/local/daos/sync_state_dao.dart';
import 'package:app/data/local/daos/weight_dao.dart';
import 'package:app/data/local/tables/blood_glucose_readings.dart';
import 'package:app/data/local/tables/blood_pressure_readings.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:app/data/local/tables/sync_state.dart';
import 'package:app/data/local/tables/weight_readings.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

export 'package:app/data/local/daos/blood_glucose_dao.dart';
export 'package:app/data/local/daos/blood_pressure_dao.dart';
export 'package:app/data/local/daos/patients_dao.dart';
export 'package:app/data/local/daos/sync_state_dao.dart';
export 'package:app/data/local/daos/weight_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Patients,
    BloodPressureReadings,
    BloodGlucoseReadings,
    WeightReadings,
    SyncState,
  ],
  daos: [
    PatientsDao,
    BloodPressureDao,
    BloodGlucoseDao,
    WeightDao,
    SyncStateDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          // Future schema bumps add steps here.
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
      await delete(patients).go();
      await delete(syncState).go();
    });
  }
}
