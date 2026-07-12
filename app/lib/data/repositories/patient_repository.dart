import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_preferences.dart';
import 'package:uuid/uuid.dart';

class PatientRepository {
  PatientRepository({
    required AppDatabase db,
    void Function()? onWrite,
  })  : _db = db,
        _onWrite = onWrite ?? (() {});

  final AppDatabase _db;
  final void Function() _onWrite;

  Future<Patient?> getPatientForAuthUser(String authUserId) {
    return _db.patientsDao.getActiveByAuthUserId(authUserId);
  }

  Future<PatientPreferences?> getPreferencesForAuthUser(String authUserId) async {
    final patient = await getPatientForAuthUser(authUserId);
    if (patient == null) {
      return null;
    }
    return _db.patientPreferencesDao.getActiveByPatientId(patient.id);
  }

  /// Returns existing prefs, or seeds local defaults (synced via remapped push).
  Future<PatientPreferences?> getOrCreatePreferencesForAuthUser(
    String authUserId,
  ) async {
    final patient = await getPatientForAuthUser(authUserId);
    if (patient == null) {
      return null;
    }

    final existing =
        await _db.patientPreferencesDao.getActiveByPatientId(patient.id);
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now().toUtc();
    final seeded = PatientPreferences(
      id: const Uuid().v4(),
      patientId: patient.id,
      createdAt: now,
      updatedAt: now,
    );
    await _db.patientPreferencesDao.insertPreferences(seeded, isDirty: true);
    _onWrite();
    return seeded;
  }

  Future<void> updateProfile(Patient patient) async {
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
        createdAt: patient.createdAt ?? now,
        updatedAt: now,
        deletedAt: patient.deletedAt,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> updatePreferences(PatientPreferences preferences) async {
    final now = DateTime.now().toUtc();
    await _db.patientPreferencesDao.updatePreferences(
      preferences.copyWith(updatedAt: now),
      isDirty: true,
    );
    _onWrite();
  }
}
