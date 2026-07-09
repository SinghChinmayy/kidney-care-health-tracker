import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:drift/drift.dart';

extension FluidIntakeRowMapper on FluidIntakeRow {
  FluidIntakeLog toDomain() {
    return FluidIntakeLog(
      id: id,
      patientId: patientId,
      recordedAt: recordedAt,
      fluidMl: fluidMl,
      source: source,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension FluidIntakeDomainMapper on FluidIntakeLog {
  FluidIntakeLogsCompanion toCompanion({required bool isDirty}) {
    final now = DateTime.now().toUtc();
    return FluidIntakeLogsCompanion.insert(
      id: id,
      patientId: patientId ?? '',
      recordedAt: recordedAt,
      fluidMl: fluidMl,
      source: Value(source),
      notes: Value(notes),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }
}
