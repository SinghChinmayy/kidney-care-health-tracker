import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/patient_preferences.dart';
import 'package:drift/drift.dart';

extension PatientPreferencesRowMapper on PatientPreferencesRow {
  PatientPreferences toDomain() {
    return PatientPreferences(
      id: id,
      patientId: patientId,
      weightUnit: weightUnit,
      bloodGlucoseUnit: bloodGlucoseUnit,
      dailyWaterGoalMl: dailyWaterGoalMl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension PatientPreferencesDomainMapper on PatientPreferences {
  PatientPrefsCompanion toCompanion({required bool isDirty}) {
    final now = DateTime.now().toUtc();
    return PatientPrefsCompanion.insert(
      id: id,
      patientId: patientId,
      weightUnit: Value(weightUnit),
      bloodGlucoseUnit: Value(bloodGlucoseUnit),
      dailyWaterGoalMl: Value(dailyWaterGoalMl),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }
}
