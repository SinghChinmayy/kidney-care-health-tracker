import 'package:app/data/local/app_database.dart';
import 'package:app/domain/errors/profile_update_requires_network.dart';
import 'package:app/domain/models/patient.dart';
import 'package:uuid/uuid.dart';

class PatientRepository {
  PatientRepository({
    required AppDatabase db,
    required Future<bool> Function() isOnline,
    void Function()? onWrite,
  })  : _db = db,
        _isOnline = isOnline,
        _onWrite = onWrite ?? (() {});

  final AppDatabase _db;
  final Future<bool> Function() _isOnline;
  final void Function() _onWrite;

  Future<Patient?> getPatientForAuthUser(String authUserId) {
    return _db.patientsDao.getActiveByAuthUserId(authUserId);
  }

  /// Ensures a local patients row exists until Stage 4 pull replaces this seed.
  Future<Patient> ensureLocalPatient(String authUserId) async {
    final existing = await _db.patientsDao.getActiveByAuthUserId(authUserId);
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now().toUtc();
    final patient = Patient(
      id: const Uuid().v4(),
      authUserId: authUserId,
      createdAt: now,
      updatedAt: now,
    );
    await _db.patientsDao.insertPatient(patient, isDirty: true);
    _onWrite();
    return patient;
  }

  Future<void> updateProfile(Patient patient) async {
    if (!await _isOnline()) {
      throw const ProfileUpdateRequiresNetworkException();
    }

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
        heightCm: patient.heightCm,
        createdAt: patient.createdAt ?? now,
        updatedAt: now,
        deletedAt: patient.deletedAt,
      ),
      isDirty: true,
    );
    _onWrite();
  }
}
