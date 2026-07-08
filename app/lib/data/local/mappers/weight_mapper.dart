import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:drift/drift.dart';

extension WeightRowMapper on WeightRow {
  WeightReading toDomain() {
    return WeightReading(
      id: id,
      patientId: patientId,
      recordedAt: recordedAt,
      valueKg: valueKg,
      dialysisTiming: dialysisTiming.isEmpty
          ? dialysisTimingNonDialysis
          : dialysisTiming,
      weightContext: weightContext,
      source: source,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension WeightDomainMapper on WeightReading {
  WeightReadingsCompanion toCompanion({required bool isDirty}) {
    final now = DateTime.now().toUtc();
    return WeightReadingsCompanion.insert(
      id: id,
      patientId: patientId ?? '',
      recordedAt: recordedAt,
      valueKg: valueKg,
      dialysisTiming: Value(dialysisTiming),
      weightContext: Value(weightContext),
      source: Value(source),
      notes: Value(notes),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }
}
