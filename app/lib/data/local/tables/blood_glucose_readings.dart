import 'package:drift/drift.dart';
import 'package:app/data/local/tables/patients.dart';

@DataClassName('BloodGlucoseRow')
class BloodGlucoseReadings extends Table {
  TextColumn get id => text()();

  TextColumn get patientId =>
      text().references(Patients, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get recordedAt => dateTime()();

  RealColumn get valueMgDl => real()();

  TextColumn get context => text().nullable()();

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
