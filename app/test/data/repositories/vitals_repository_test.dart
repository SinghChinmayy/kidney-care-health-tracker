import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/errors/profile_update_requires_network.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late PatientRepository patientRepository;
  late VitalsRepository vitalsRepository;
  var writeCount = 0;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    writeCount = 0;
    patientRepository = PatientRepository(
      db: db,
      isOnline: () async => false,
      onWrite: () => writeCount++,
    );
    vitalsRepository = VitalsRepository(
      db: db,
      patientRepository: patientRepository,
      currentAuthUserId: () => 'auth-user-1',
      onWrite: () => writeCount++,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('addBloodPressureReading persists and is readable', () async {
    const readingId = 'bp-test-1';
    final recordedAt = DateTime.utc(2026, 7, 8, 8);

    await vitalsRepository.addBloodPressureReading(
      BloodPressureReading(
        id: readingId,
        recordedAt: recordedAt,
        systolic: 118,
        diastolic: 76,
      ),
    );

    final readings = await vitalsRepository.getBloodPressureReadings();
    expect(readings, hasLength(1));
    expect(readings.first.id, readingId);
    expect(readings.first.systolic, 118);
    expect(readings.first.patientId, isNotNull);
    expect(writeCount, 2);

    final patient = await patientRepository.getPatientForAuthUser('auth-user-1');
    expect(patient, isNotNull);
  });

  test('deleteBloodPressureReading soft-deletes row from active reads', () async {
    const readingId = 'bp-delete-1';
    final recordedAt = DateTime.utc(2026, 7, 8, 9);

    await vitalsRepository.addBloodPressureReading(
      BloodPressureReading(
        id: readingId,
        recordedAt: recordedAt,
        systolic: 130,
        diastolic: 85,
      ),
    );

    await vitalsRepository.deleteBloodPressureReading(readingId);

    final active = await vitalsRepository.getBloodPressureReadings();
    expect(active, isEmpty);

    final dirty = await db.bloodPressureDao.getDirtyRows();
    expect(dirty, hasLength(1));
    expect(dirty.first.deletedAt, isNotNull);
  });

  test('updateProfile throws when offline', () async {
    final patient = await patientRepository.ensureLocalPatient('auth-user-2');

    expect(
      () => patientRepository.updateProfile(
        Patient(
          id: patient.id,
          authUserId: patient.authUserId,
          firstName: 'Grace',
          lastName: 'Hopper',
        ),
      ),
      throwsA(isA<ProfileUpdateRequiresNetworkException>()),
    );
  });

  test('updateProfile succeeds when online', () async {
    final onlinePatients = PatientRepository(
      db: db,
      isOnline: () async => true,
      onWrite: () => writeCount++,
    );

    final patient = await onlinePatients.ensureLocalPatient('auth-user-3');

    await onlinePatients.updateProfile(
      Patient(
        id: patient.id,
        authUserId: patient.authUserId,
        firstName: 'Ada',
        lastName: 'Lovelace',
        createdAt: patient.createdAt,
      ),
    );

    final loaded = await onlinePatients.getPatientForAuthUser('auth-user-3');
    expect(loaded?.firstName, 'Ada');
    expect(loaded?.lastName, 'Lovelace');
  });

  test('getPatientForAuthUser reads profile offline', () async {
    final patient = await patientRepository.ensureLocalPatient('auth-user-4');
    final loaded = await patientRepository.getPatientForAuthUser('auth-user-4');
    expect(loaded?.id, patient.id);
  });

  test('vitals use client-generated UUID ids', () async {
    final id = const Uuid().v4();
    await vitalsRepository.addBloodPressureReading(
      BloodPressureReading(
        id: id,
        recordedAt: DateTime.utc(2026, 7, 8, 10),
        systolic: 120,
        diastolic: 80,
      ),
    );

    final latest = await vitalsRepository.getLatestBloodPressure();
    expect(latest?.id, id);
  });
}
