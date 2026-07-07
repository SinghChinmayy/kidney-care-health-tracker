import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:drift/drift.dart';

extension BloodGlucoseRowMapper on BloodGlucoseRow {
  BloodGlucoseReading toDomain() {
    return BloodGlucoseReading(
      id: id,
      patientId: patientId,
      recordedAt: recordedAt,
      valueMgDl: valueMgDl,
      context: context,
      source: source,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension BloodGlucoseDomainMapper on BloodGlucoseReading {
  BloodGlucoseReadingsCompanion toCompanion({required bool isDirty}) {
    final now = DateTime.now().toUtc();
    return BloodGlucoseReadingsCompanion.insert(
      id: id,
      patientId: patientId ?? '',
      recordedAt: recordedAt,
      valueMgDl: valueMgDl,
      context: Value(context),
      source: Value(source),
      notes: Value(notes),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }
}
