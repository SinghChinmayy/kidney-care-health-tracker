import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/active_patient_notifier.dart';
import 'package:app/data/services/patient_access_remote.dart';
import 'package:app/data/sync/remote_mappers.dart';
import 'package:app/domain/models/accessible_patient.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_preferences.dart';
import 'package:app/domain/models/patient_role.dart';
import 'package:uuid/uuid.dart';

class PatientRepository {
  PatientRepository({
    required AppDatabase db,
    void Function()? onWrite,
    PatientAccessRemote? remote,
    ActivePatientNotifier? activePatientNotifier,
  })  : _db = db,
        _onWrite = onWrite ?? (() {}),
        _remote = remote,
        _notifier = activePatientNotifier;

  final AppDatabase _db;
  final void Function() _onWrite;
  final PatientAccessRemote? _remote;
  final ActivePatientNotifier? _notifier;

  /// The signed-in user's own (self) patient record.
  Future<Patient?> getPatientForAuthUser(String authUserId) {
    return _db.patientsDao.getActiveByAuthUserId(authUserId);
  }

  // --- Access & active patient -------------------------------------------

  /// Role of [authUserId] on [patientId] from the synced membership cache.
  /// Before the first access sync the self patient counts as owned.
  Future<PatientRole?> roleFor(String patientId, String authUserId) async {
    final membership = await _db.patientAccessDao.getMembership(patientId);
    final role = PatientRole.fromWire(membership?.role);
    if (role != null) {
      return role;
    }
    final patient = await _db.patientsDao.getActiveById(patientId);
    if (patient != null && patient.authUserId == authUserId) {
      return PatientRole.owner;
    }
    return null;
  }

  /// Patient currently being viewed/logged for: the persisted pick if it is
  /// still accessible, otherwise the user's own record.
  Future<Patient?> getActivePatient(String authUserId) async {
    final storedId =
        await _db.patientAccessDao.getSetting(activePatientSettingKey);
    if (storedId != null) {
      final stored = await _db.patientsDao.getActiveById(storedId);
      if (stored != null && await roleFor(stored.id, authUserId) != null) {
        return stored;
      }
    }
    return getPatientForAuthUser(authUserId);
  }

  Future<PatientRole?> getActiveRole(String authUserId) async {
    final patient = await getActivePatient(authUserId);
    if (patient == null) {
      return null;
    }
    return roleFor(patient.id, authUserId);
  }

  Future<void> setActivePatient(String patientId) async {
    await _db.patientAccessDao.setSetting(activePatientSettingKey, patientId);
    _notifier?.markChanged();
  }

  /// Every locally cached patient the user can access, self first.
  Future<List<AccessiblePatient>> listAccessiblePatients(
    String authUserId,
  ) async {
    final self = await getPatientForAuthUser(authUserId);
    final result = <AccessiblePatient>[];
    final seen = <String>{};
    if (self != null) {
      result.add(
        AccessiblePatient(
          patient: self,
          role: await roleFor(self.id, authUserId) ?? PatientRole.owner,
          isSelf: true,
        ),
      );
      seen.add(self.id);
    }

    final others = <AccessiblePatient>[];
    for (final membership in await _db.patientAccessDao.getMemberships()) {
      if (seen.contains(membership.patientId)) {
        continue;
      }
      final patient =
          await _db.patientsDao.getActiveById(membership.patientId);
      final role = PatientRole.fromWire(membership.role);
      if (patient == null || role == null) {
        continue; // not pulled yet
      }
      others.add(
        AccessiblePatient(patient: patient, role: role, isSelf: false),
      );
    }
    others.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
    );
    return [...result, ...others];
  }

  /// Creates a patient on the server (caller becomes owner), caches it
  /// locally and makes it active. Requires a connection.
  Future<Patient> createPatient({
    required String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? sex,
    String? bloodGroup,
  }) async {
    final remote = _remote;
    if (remote == null) {
      throw StateError('Patient creation needs a server connection.');
    }
    final json = await remote.createPatient(
      id: const Uuid().v4(),
      firstName: firstName.trim(),
      lastName: lastName?.trim(),
      dateOfBirth: dateOfBirth,
      sex: sex,
      bloodGroup: bloodGroup,
    );
    final row = patientRowFromRemoteJson(json);
    await _db.transaction(() async {
      await _db.patientsDao.upsertRemoteRow(row, isDirty: false);
      await _db.patientAccessDao.upsertMembership(
        patientId: row.id,
        role: PatientRole.owner.wire,
        updatedAt: row.updatedAt,
      );
    });
    await setActivePatient(row.id);
    // Pull the server-bootstrapped preferences row.
    _onWrite();
    return (await _db.patientsDao.getActiveById(row.id))!;
  }

  Future<void> _assertCanWrite(String patientId, String? authUserId) async {
    if (authUserId == null) {
      return; // legacy single-user callers/tests
    }
    final role = await roleFor(patientId, authUserId);
    if (role == null || !role.canWrite) {
      throw const ReadOnlyPatientException();
    }
  }

  // --- Preferences ---------------------------------------------------------

  Future<PatientPreferences?> getPreferencesForPatient(String patientId) {
    return _db.patientPreferencesDao.getActiveByPatientId(patientId);
  }

  Future<PatientPreferences?> getPreferencesForAuthUser(
    String authUserId,
  ) async {
    final patient = await getPatientForAuthUser(authUserId);
    if (patient == null) {
      return null;
    }
    return getPreferencesForPatient(patient.id);
  }

  /// Returns existing prefs, or seeds local defaults (synced via remapped
  /// push). Viewers never seed: they just get null until a pull lands.
  Future<PatientPreferences?> getOrCreatePreferencesForPatient(
    String patientId, {
    String? authUserId,
  }) async {
    final existing =
        await _db.patientPreferencesDao.getActiveByPatientId(patientId);
    if (existing != null) {
      return existing;
    }
    if (authUserId != null) {
      final role = await roleFor(patientId, authUserId);
      if (role == null || !role.canWrite) {
        return null;
      }
    }

    final now = DateTime.now().toUtc();
    final seeded = PatientPreferences(
      id: const Uuid().v4(),
      patientId: patientId,
      createdAt: now,
      updatedAt: now,
    );
    await _db.patientPreferencesDao.insertPreferences(seeded, isDirty: true);
    _onWrite();
    return seeded;
  }

  Future<PatientPreferences?> getOrCreatePreferencesForAuthUser(
    String authUserId,
  ) async {
    final patient = await getPatientForAuthUser(authUserId);
    if (patient == null) {
      return null;
    }
    return getOrCreatePreferencesForPatient(patient.id);
  }

  // --- Writes ----------------------------------------------------------------

  Future<void> updateProfile(Patient patient, {String? authUserId}) async {
    await _assertCanWrite(patient.id, authUserId);
    final now = DateTime.now().toUtc();
    await _db.patientsDao.updatePatient(
      Patient(
        id: patient.id,
        authUserId: patient.authUserId,
        firstName: patient.firstName,
        lastName: patient.lastName,
        dateOfBirth: patient.dateOfBirth,
        sex: patient.sex,
        ckdStage: patient.ckdStage,
        dialysisType: patient.dialysisType,
        dialysisDaysOfWeek: patient.dialysisDaysOfWeek,
        heightCm: patient.heightCm,
        bloodGroup: patient.bloodGroup,
        createdAt: patient.createdAt ?? now,
        updatedAt: now,
        deletedAt: patient.deletedAt,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> updatePreferences(
    PatientPreferences preferences, {
    String? authUserId,
  }) async {
    await _assertCanWrite(preferences.patientId, authUserId);
    final now = DateTime.now().toUtc();
    await _db.patientPreferencesDao.updatePreferences(
      preferences.copyWith(updatedAt: now),
      isDirty: true,
    );
    _onWrite();
  }
}
