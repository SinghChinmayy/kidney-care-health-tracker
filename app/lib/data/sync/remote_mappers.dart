import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/converters/dialysis_days_of_week_converter.dart';
import 'package:app/data/sync/sync_utils.dart';
import 'package:app/domain/models/weight_reading_options.dart';

Map<String, dynamic> patientRowToRemoteJson(PatientRow row) {
  return {
    'id': row.id,
    'auth_user_id': row.authUserId,
    'first_name': row.firstName,
    'last_name': row.lastName,
    'date_of_birth': remoteIsoDate(row.dateOfBirth),
    'sex': row.sex,
    'ckd_stage': row.ckdStage,
    'dialysis_type': row.dialysisType,
    'dialysis_days_of_week': row.dialysisDaysOfWeek,
    'height_cm': row.heightCm,
    'created_at': remoteIsoDateTime(row.createdAt),
    'updated_at': remoteIsoDateTime(row.updatedAt),
    'deleted_at': remoteIsoDateTime(row.deletedAt),
  };
}

PatientRow patientRowFromRemoteJson(Map<String, dynamic> json) {
  return PatientRow(
    id: json['id'] as String,
    authUserId: json['auth_user_id'] as String,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    dateOfBirth: parseRemoteDateOrNull(json['date_of_birth']),
    sex: json['sex'] as String?,
    ckdStage: json['ckd_stage'] as String?,
    dialysisType: json['dialysis_type'] as String? ?? 'none',
    dialysisDaysOfWeek: parseDialysisDaysOfWeek(json['dialysis_days_of_week']),
    heightCm: parseRemoteDouble(json['height_cm']),
    createdAt: parseRemoteDateTime(json['created_at']),
    updatedAt: parseRemoteDateTime(json['updated_at']),
    deletedAt: parseRemoteDateTimeOrNull(json['deleted_at']),
    isDirty: false,
  );
}

Map<String, dynamic> bloodPressureRowToRemoteJson(BloodPressureRow row) {
  return {
    'id': row.id,
    'patient_id': row.patientId,
    'recorded_at': remoteIsoDateTime(row.recordedAt),
    'systolic': row.systolic,
    'diastolic': row.diastolic,
    'heart_rate_bpm': row.heartRateBpm,
    'notes': row.notes,
    'created_at': remoteIsoDateTime(row.createdAt),
    'updated_at': remoteIsoDateTime(row.updatedAt),
    'deleted_at': remoteIsoDateTime(row.deletedAt),
  };
}

BloodPressureRow bloodPressureRowFromRemoteJson(Map<String, dynamic> json) {
  return BloodPressureRow(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    recordedAt: parseRemoteDateTime(json['recorded_at']),
    systolic: parseRemoteInt(json['systolic']),
    diastolic: parseRemoteInt(json['diastolic']),
    heartRateBpm: parseRemoteInt(json['heart_rate_bpm']),
    notes: json['notes'] as String?,
    createdAt: parseRemoteDateTime(json['created_at']),
    updatedAt: parseRemoteDateTime(json['updated_at']),
    deletedAt: parseRemoteDateTimeOrNull(json['deleted_at']),
    isDirty: false,
  );
}

Map<String, dynamic> bloodGlucoseRowToRemoteJson(BloodGlucoseRow row) {
  return {
    'id': row.id,
    'patient_id': row.patientId,
    'recorded_at': remoteIsoDateTime(row.recordedAt),
    'value_mg_dl': row.valueMgDl,
    'context': row.context,
    'source': row.source,
    'notes': row.notes,
    'created_at': remoteIsoDateTime(row.createdAt),
    'updated_at': remoteIsoDateTime(row.updatedAt),
    'deleted_at': remoteIsoDateTime(row.deletedAt),
  };
}

BloodGlucoseRow bloodGlucoseRowFromRemoteJson(Map<String, dynamic> json) {
  return BloodGlucoseRow(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    recordedAt: parseRemoteDateTime(json['recorded_at']),
    valueMgDl: parseRemoteDouble(json['value_mg_dl']) ?? 0,
    context: json['context'] as String?,
    source: json['source'] as String? ?? 'manual',
    notes: json['notes'] as String?,
    createdAt: parseRemoteDateTime(json['created_at']),
    updatedAt: parseRemoteDateTime(json['updated_at']),
    deletedAt: parseRemoteDateTimeOrNull(json['deleted_at']),
    isDirty: false,
  );
}

Map<String, dynamic> weightRowToRemoteJson(WeightRow row) {
  return {
    'id': row.id,
    'patient_id': row.patientId,
    'recorded_at': remoteIsoDateTime(row.recordedAt),
    'value_kg': row.valueKg,
    'dialysis_timing': row.dialysisTiming,
    'weight_context': row.weightContext,
    'source': row.source,
    'notes': row.notes,
    'created_at': remoteIsoDateTime(row.createdAt),
    'updated_at': remoteIsoDateTime(row.updatedAt),
    'deleted_at': remoteIsoDateTime(row.deletedAt),
  };
}

WeightRow weightRowFromRemoteJson(Map<String, dynamic> json) {
  return WeightRow(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    recordedAt: parseRemoteDateTime(json['recorded_at']),
    valueKg: parseRemoteDouble(json['value_kg']) ?? 0,
    dialysisTiming:
        json['dialysis_timing'] as String? ?? dialysisTimingNonDialysis,
    weightContext: json['weight_context'] as String?,
    source: json['source'] as String? ?? 'manual',
    notes: json['notes'] as String?,
    createdAt: parseRemoteDateTime(json['created_at']),
    updatedAt: parseRemoteDateTime(json['updated_at']),
    deletedAt: parseRemoteDateTimeOrNull(json['deleted_at']),
    isDirty: false,
  );
}

Map<String, dynamic> fluidIntakeRowToRemoteJson(FluidIntakeRow row) {
  return {
    'id': row.id,
    'patient_id': row.patientId,
    'recorded_at': remoteIsoDateTime(row.recordedAt),
    'fluid_ml': row.fluidMl,
    'source': row.source,
    'notes': row.notes,
    'created_at': remoteIsoDateTime(row.createdAt),
    'updated_at': remoteIsoDateTime(row.updatedAt),
    'deleted_at': remoteIsoDateTime(row.deletedAt),
  };
}

FluidIntakeRow fluidIntakeRowFromRemoteJson(Map<String, dynamic> json) {
  return FluidIntakeRow(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    recordedAt: parseRemoteDateTime(json['recorded_at']),
    fluidMl: parseRemoteDouble(json['fluid_ml']) ?? 0,
    source: json['source'] as String? ?? 'manual',
    notes: json['notes'] as String?,
    createdAt: parseRemoteDateTime(json['created_at']),
    updatedAt: parseRemoteDateTime(json['updated_at']),
    deletedAt: parseRemoteDateTimeOrNull(json['deleted_at']),
    isDirty: false,
  );
}

Map<String, dynamic> patientPreferencesRowToRemoteJson(
  PatientPreferencesRow row,
) {
  return {
    'id': row.id,
    'patient_id': row.patientId,
    'weight_unit': row.weightUnit,
    'blood_glucose_unit': row.bloodGlucoseUnit,
    'daily_water_goal_ml': row.dailyWaterGoalMl,
    'created_at': remoteIsoDateTime(row.createdAt),
    'updated_at': remoteIsoDateTime(row.updatedAt),
    'deleted_at': remoteIsoDateTime(row.deletedAt),
  };
}

PatientPreferencesRow patientPreferencesRowFromRemoteJson(
  Map<String, dynamic> json,
) {
  return PatientPreferencesRow(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    weightUnit: json['weight_unit'] as String? ?? 'kg',
    bloodGlucoseUnit: json['blood_glucose_unit'] as String? ?? 'mg_dl',
    dailyWaterGoalMl: parseRemoteInt(json['daily_water_goal_ml']) ?? 1200,
    createdAt: parseRemoteDateTime(json['created_at']),
    updatedAt: parseRemoteDateTime(json['updated_at']),
    deletedAt: parseRemoteDateTimeOrNull(json['deleted_at']),
    isDirty: false,
  );
}
