import 'package:drift/drift.dart';
import 'package:app/data/local/tables/patients.dart';

@DataClassName('WeightRow')
class WeightReadings extends Table {
  TextColumn get id => text()();

  TextColumn get patientId =>
      text().references(Patients, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get recordedAt => dateTime()();

  RealColumn get valueKg => real()();

  TextColumn get dialysisTiming =>
      text().withDefault(const Constant('non_dialysis'))();

  TextColumn get weightContext => text().nullable()();

  TextColumn get source =>
      text().withDefault(const Constant('manual'))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
