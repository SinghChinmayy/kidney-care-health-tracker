import 'package:drift/drift.dart';

/// Local cache of the signed-in user's own `patient_access` rows.
///
/// Refreshed by the sync engine every run; a patient missing here after a
/// refresh has been revoked and its cached data is evicted.
@DataClassName('PatientMembershipRow')
class PatientMemberships extends Table {
  TextColumn get patientId => text()();

  /// owner | caregiver | viewer
  TextColumn get role => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {patientId};
}
