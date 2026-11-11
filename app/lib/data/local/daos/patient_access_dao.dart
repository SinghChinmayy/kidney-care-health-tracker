import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/tables/local_settings.dart';
import 'package:app/data/local/tables/patient_memberships.dart';
import 'package:drift/drift.dart';

part 'patient_access_dao.g.dart';

const activePatientSettingKey = 'active_patient_id';

@DriftAccessor(tables: [PatientMemberships, LocalSettings])
class PatientAccessDao extends DatabaseAccessor<AppDatabase>
    with _$PatientAccessDaoMixin {
  PatientAccessDao(super.db);

  Future<List<PatientMembershipRow>> getMemberships() {
    return select(patientMemberships).get();
  }

  Future<PatientMembershipRow?> getMembership(String patientId) {
    return (select(patientMemberships)
          ..where((t) => t.patientId.equals(patientId)))
        .getSingleOrNull();
  }

  Future<void> upsertMembership({
    required String patientId,
    required String role,
    required DateTime updatedAt,
  }) {
    return into(patientMemberships).insertOnConflictUpdate(
      PatientMembershipsCompanion.insert(
        patientId: patientId,
        role: role,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<void> deleteMembership(String patientId) {
    return (delete(patientMemberships)
          ..where((t) => t.patientId.equals(patientId)))
        .go();
  }

  Future<String?> getSetting(String key) async {
    final row = await (select(localSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String? value) {
    return into(localSettings).insertOnConflictUpdate(
      LocalSettingsCompanion.insert(key: key, value: Value(value)),
    );
  }
}
