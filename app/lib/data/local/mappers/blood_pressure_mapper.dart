import 'package:app/data/local/app_database.dart';
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
    return BloodPressureReadingsCompanion.insert(
      id: id,
      patientId: patientId ?? '',
      recordedAt: recordedAt,
      systolic: Value(systolic),
      diastolic: Value(diastolic),
      heartRateBpm: Value(heartRateBpm),
      notes: Value(notes),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }
}
