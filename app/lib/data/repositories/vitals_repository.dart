import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_preferences.dart';
import 'package:app/domain/models/patient_role.dart';
import 'package:app/domain/models/weight_reading.dart';

class VitalsRepository {
  VitalsRepository({
    required AppDatabase db,
    required PatientRepository patientRepository,
    required String? Function() currentAuthUserId,
    void Function()? onWrite,
  })  : _db = db,
        _patientRepository = patientRepository,
        _currentAuthUserId = currentAuthUserId,
        _onWrite = onWrite ?? (() {});

  final AppDatabase _db;
  final PatientRepository _patientRepository;
  final String? Function() _currentAuthUserId;
  final void Function() _onWrite;

  /// Readings are always scoped to the active patient (see
  /// [PatientRepository.getActivePatient]).
  Future<String?> _patientIdOrNull() async {
    final patient = await getCurrentPatient();
    return patient?.id;
  }

  Future<Patient?> getCurrentPatient() async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return null;
    }
    return _patientRepository.getActivePatient(authUserId);
  }

  Future<PatientPreferences?> getCurrentPreferences() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return null;
    }
    return _patientRepository.getPreferencesForPatient(patientId);
  }

  /// False when the signed-in user only has viewer access to the active
  /// patient.
  Future<bool> canWriteCurrentPatient() async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return false;
    }
    final role = await _patientRepository.getActiveRole(authUserId);
    return role?.canWrite ?? false;
  }

  Future<void> _assertCanWrite(String? patientId) async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null || patientId == null) {
      throw StateError('Cannot write vitals without a signed-in user.');
    }
    final role = await _patientRepository.roleFor(patientId, authUserId);
    if (role == null || !role.canWrite) {
      throw const ReadOnlyPatientException();
    }
  }

  /// Signed-in auth user id, used to label "logged by you".
  String? get currentUserId => _currentAuthUserId();

  Future<String> _requirePatientId() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      throw StateError('Cannot access vitals without a signed-in user.');
    }
    await _assertCanWrite(patientId);
    return patientId;
  }

  // --- Blood pressure ---

  Future<List<BloodPressureReading>> getBloodPressureReadings() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return [];
    }
    return _db.bloodPressureDao.getActiveForPatient(patientId);
  }

  Future<BloodPressureReading?> getLatestBloodPressure() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return null;
    }
    return _db.bloodPressureDao.getLatestForPatient(patientId);
  }

  Future<void> addBloodPressureReading(BloodPressureReading reading) async {
    final patientId = await _requirePatientId();
    final now = DateTime.now().toUtc();
    await _db.bloodPressureDao.insertReading(
      BloodPressureReading(
        id: reading.id,
        patientId: patientId,
        recordedBy: _currentAuthUserId(),
        recordedAt: reading.recordedAt,
        systolic: reading.systolic,
        diastolic: reading.diastolic,
        heartRateBpm: reading.heartRateBpm,
        context: reading.context,
        notes: reading.notes,
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> updateBloodPressureReading(BloodPressureReading reading) async {
    await _assertCanWrite(reading.patientId);
    final now = DateTime.now().toUtc();
    await _db.bloodPressureDao.updateReading(
      BloodPressureReading(
        id: reading.id,
        patientId: reading.patientId,
        recordedAt: reading.recordedAt,
        systolic: reading.systolic,
        diastolic: reading.diastolic,
        heartRateBpm: reading.heartRateBpm,
        context: reading.context,
        notes: reading.notes,
        createdAt: reading.createdAt,
        updatedAt: now,
        deletedAt: reading.deletedAt,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> deleteBloodPressureReading(String id) async {
    await _assertCanWrite((await _db.bloodPressureDao.getRowById(id))?.patientId);
    final now = DateTime.now().toUtc();
    await _db.bloodPressureDao.softDelete(id, now);
    _onWrite();
  }

  // --- Blood glucose ---

  Future<List<BloodGlucoseReading>> getBloodGlucoseReadings() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return [];
    }
    return _db.bloodGlucoseDao.getActiveForPatient(patientId);
  }

  Future<BloodGlucoseReading?> getLatestBloodGlucose() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return null;
    }
    return _db.bloodGlucoseDao.getLatestForPatient(patientId);
  }

  Future<void> addBloodGlucoseReading(BloodGlucoseReading reading) async {
    final patientId = await _requirePatientId();
    final now = DateTime.now().toUtc();
    await _db.bloodGlucoseDao.insertReading(
      BloodGlucoseReading(
        id: reading.id,
        patientId: patientId,
        recordedBy: _currentAuthUserId(),
        recordedAt: reading.recordedAt,
        valueMgDl: reading.valueMgDl,
        context: reading.context,
        source: reading.source,
        notes: reading.notes,
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> updateBloodGlucoseReading(BloodGlucoseReading reading) async {
    await _assertCanWrite(reading.patientId);
    final now = DateTime.now().toUtc();
    await _db.bloodGlucoseDao.updateReading(
      BloodGlucoseReading(
        id: reading.id,
        patientId: reading.patientId,
        recordedAt: reading.recordedAt,
        valueMgDl: reading.valueMgDl,
        context: reading.context,
        source: reading.source,
        notes: reading.notes,
        createdAt: reading.createdAt,
        updatedAt: now,
        deletedAt: reading.deletedAt,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> deleteBloodGlucoseReading(String id) async {
    await _assertCanWrite((await _db.bloodGlucoseDao.getRowById(id))?.patientId);
    final now = DateTime.now().toUtc();
    await _db.bloodGlucoseDao.softDelete(id, now);
    _onWrite();
  }

  // --- Weight ---

  Future<List<WeightReading>> getWeightReadings() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return [];
    }
    return _db.weightDao.getActiveForPatient(patientId);
  }

  Future<WeightReading?> getLatestWeight() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return null;
    }
    return _db.weightDao.getLatestForPatient(patientId);
  }

  Future<void> addWeightReading(WeightReading reading) async {
    final patientId = await _requirePatientId();
    final now = DateTime.now().toUtc();
    await _db.weightDao.insertReading(
      WeightReading(
        id: reading.id,
        patientId: patientId,
        recordedBy: _currentAuthUserId(),
        recordedAt: reading.recordedAt,
        valueKg: reading.valueKg,
        dialysisTiming: reading.dialysisTiming,
        weightContext: reading.weightContext,
        source: reading.source,
        notes: reading.notes,
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> updateWeightReading(WeightReading reading) async {
    await _assertCanWrite(reading.patientId);
    final now = DateTime.now().toUtc();
    await _db.weightDao.updateReading(
      WeightReading(
        id: reading.id,
        patientId: reading.patientId,
        recordedAt: reading.recordedAt,
        valueKg: reading.valueKg,
        dialysisTiming: reading.dialysisTiming,
        weightContext: reading.weightContext,
        source: reading.source,
        notes: reading.notes,
        createdAt: reading.createdAt,
        updatedAt: now,
        deletedAt: reading.deletedAt,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> deleteWeightReading(String id) async {
    await _assertCanWrite((await _db.weightDao.getRowById(id))?.patientId);
    final now = DateTime.now().toUtc();
    await _db.weightDao.softDelete(id, now);
    _onWrite();
  }

  // --- Fluid intake ---

  Future<List<FluidIntakeLog>> getFluidIntakeLogs() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return [];
    }
    return _db.fluidIntakeDao.getActiveForPatient(patientId);
  }

  Future<FluidIntakeLog?> getLatestFluidIntake() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return null;
    }
    return _db.fluidIntakeDao.getLatestForPatient(patientId);
  }

  Future<void> addFluidIntakeLog(FluidIntakeLog log) async {
    final patientId = await _requirePatientId();
    final now = DateTime.now().toUtc();
    await _db.fluidIntakeDao.insertLog(
      FluidIntakeLog(
        id: log.id,
        patientId: patientId,
        recordedBy: _currentAuthUserId(),
        recordedAt: log.recordedAt,
        fluidMl: log.fluidMl,
        source: log.source,
        notes: log.notes,
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> updateFluidIntakeLog(FluidIntakeLog log) async {
    await _assertCanWrite(log.patientId);
    final now = DateTime.now().toUtc();
    await _db.fluidIntakeDao.updateLog(
      FluidIntakeLog(
        id: log.id,
        patientId: log.patientId,
        recordedAt: log.recordedAt,
        fluidMl: log.fluidMl,
        source: log.source,
        notes: log.notes,
        createdAt: log.createdAt,
        updatedAt: now,
        deletedAt: log.deletedAt,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> deleteFluidIntakeLog(String id) async {
    await _assertCanWrite((await _db.fluidIntakeDao.getRowById(id))?.patientId);
    final now = DateTime.now().toUtc();
    await _db.fluidIntakeDao.softDelete(id, now);
    _onWrite();
  }
}
