import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
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

  Future<String?> _patientIdOrNull() async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return null;
    }
    final patient = await _patientRepository.ensureLocalPatient(authUserId);
    return patient.id;
  }

  Future<String> _requirePatientId() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      throw StateError('Cannot access vitals without a signed-in user.');
    }
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
        recordedAt: reading.recordedAt,
        systolic: reading.systolic,
        diastolic: reading.diastolic,
        heartRateBpm: reading.heartRateBpm,
        notes: reading.notes,
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: true,
    );
    _onWrite();
  }

  Future<void> updateBloodPressureReading(BloodPressureReading reading) async {
    final now = DateTime.now().toUtc();
    await _db.bloodPressureDao.updateReading(
      BloodPressureReading(
        id: reading.id,
        patientId: reading.patientId,
        recordedAt: reading.recordedAt,
        systolic: reading.systolic,
        diastolic: reading.diastolic,
        heartRateBpm: reading.heartRateBpm,
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
        recordedAt: reading.recordedAt,
        valueKg: reading.valueKg,
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
    final now = DateTime.now().toUtc();
    await _db.weightDao.updateReading(
      WeightReading(
        id: reading.id,
        patientId: reading.patientId,
        recordedAt: reading.recordedAt,
        valueKg: reading.valueKg,
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
    final now = DateTime.now().toUtc();
    await _db.weightDao.softDelete(id, now);
    _onWrite();
  }
}
