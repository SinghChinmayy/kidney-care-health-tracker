import 'package:drift/drift.dart';

@DataClassName('PatientRow')
class Patients extends Table {
  TextColumn get id => text()();

  TextColumn get authUserId => text().unique()();

  TextColumn get firstName => text().nullable()();

  TextColumn get lastName => text().nullable()();

  DateTimeColumn get dateOfBirth => dateTime().nullable()();

  TextColumn get sex => text().nullable()();

  TextColumn get ckdStage => text().nullable()();

  TextColumn get dialysisType =>
      text().withDefault(const Constant('none'))();

  RealColumn get heightCm => real().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
