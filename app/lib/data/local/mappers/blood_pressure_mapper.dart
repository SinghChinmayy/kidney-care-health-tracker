import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/blood_pressure_context.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:drift/drift.dart';

extension BloodPressureRowMapper on BloodPressureRow {
  BloodPressureReading toDomain() {
    return BloodPressureReading(
      id: id,
      patientId: patientId,
      recordedAt: recordedAt,
      systolic: systolic,
      diastolic: diastolic,
      heartRateBpm: heartRateBpm,
      context: BloodPressureContext(
        arm: arm,
        posture: posture,
        isDialysisDay: isDialysisDay,
        dialysisPhase: dialysisPhase,
      ),
      recordedBy: recordedBy,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension BloodPressureDomainMapper on BloodPressureReading {
  BloodPressureReadingsCompanion toCompanion({required bool isDirty}) {
    final now = DateTime.now().toUtc();
    final normalizedContext = context.normalized();
    return BloodPressureReadingsCompanion.insert(
      id: id,
      patientId: patientId ?? '',
      recordedAt: recordedAt,
      systolic: Value(systolic),
      diastolic: Value(diastolic),
      heartRateBpm: Value(heartRateBpm),
      arm: Value(normalizedContext.arm),
      posture: Value(normalizedContext.posture),
      isDialysisDay: Value(normalizedContext.isDialysisDay),
      dialysisPhase: Value(normalizedContext.dialysisPhase),
      recordedBy: Value(recordedBy),
      notes: Value(notes),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }
}
