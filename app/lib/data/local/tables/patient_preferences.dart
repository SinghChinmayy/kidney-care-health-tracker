import 'package:drift/drift.dart';
import 'package:app/data/local/tables/patients.dart';

@DataClassName('PatientPreferencesRow')
class PatientPrefs extends Table {
  TextColumn get id => text()();

  TextColumn get patientId =>
      text().unique().references(Patients, #id, onDelete: KeyAction.cascade)();

  TextColumn get weightUnit =>
      text().withDefault(const Constant('kg'))();

  TextColumn get bloodGlucoseUnit =>
      text().withDefault(const Constant('mg_dl'))();

  IntColumn get dailyWaterGoalMl =>
      integer().withDefault(const Constant(1200))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
