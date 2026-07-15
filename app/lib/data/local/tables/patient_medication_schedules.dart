import 'package:app/data/local/converters/medication_schedule_converter.dart';
import 'package:app/data/local/tables/patients.dart';
import 'package:drift/drift.dart';

@DataClassName('PatientMedicationScheduleRow')
class PatientMedicationSchedules extends Table {
  TextColumn get id => text()();

  TextColumn get patientId =>
      text().unique().references(Patients, #id, onDelete: KeyAction.cascade)();

  TextColumn get schedule => text()
      .map(const MedicationScheduleConverter())
      .withDefault(const Constant('{"by_day":{}}'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
