import 'package:drift/drift.dart';
import 'package:app/data/local/tables/patients.dart';

@DataClassName('BloodPressureRow')
class BloodPressureReadings extends Table {
  TextColumn get id => text()();

  TextColumn get patientId =>
      text().references(Patients, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get recordedAt => dateTime()();

  IntColumn get systolic => integer().nullable()();

  IntColumn get diastolic => integer().nullable()();

  IntColumn get heartRateBpm => integer().nullable()();

  TextColumn get arm => text().nullable()();

  TextColumn get posture => text().nullable()();

  BoolColumn get isDialysisDay => boolean().nullable()();

  TextColumn get dialysisPhase => text().nullable()();

  /// auth user id that logged the row (server-set, see s2.2).
  TextColumn get recordedBy => text().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
