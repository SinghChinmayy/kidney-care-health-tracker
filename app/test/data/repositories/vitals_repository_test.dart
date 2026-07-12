import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_preferences.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

Future<Patient> seedPatient(
  AppDatabase db, {
  required String authUserId,
  String id = 'patient-1',
}) async {
  final now = DateTime.utc(2026, 7, 8, 8);
  final patient = Patient(
    id: id,
    authUserId: authUserId,
    createdAt: now,
    updatedAt: now,
  );
  await db.patientsDao.insertPatient(patient, isDirty: false);
  return patient;
}

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
    await seedPatient(db, authUserId: 'auth-user-1');

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
    expect(readings.first.patientId, 'patient-1');
    expect(writeCount, 1);

    final patient = await patientRepository.getPatientForAuthUser('auth-user-1');
    expect(patient, isNotNull);
  });

  test('addBloodPressureReading requires an existing local patient', () async {
    expect(
      () => vitalsRepository.addBloodPressureReading(
        BloodPressureReading(
          id: 'bp-missing-patient',
          recordedAt: DateTime.utc(2026, 7, 8, 8),
          systolic: 120,
          diastolic: 80,
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('deleteBloodPressureReading soft-deletes row from active reads', () async {
    await seedPatient(db, authUserId: 'auth-user-1');

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

  test('updateProfile persists locally when offline', () async {
    final patient = await seedPatient(db, authUserId: 'auth-user-2', id: 'p-2');
    writeCount = 0;

    await patientRepository.updateProfile(
      Patient(
        id: patient.id,
        authUserId: patient.authUserId,
        firstName: 'Grace',
        lastName: 'Hopper',
        createdAt: patient.createdAt,
      ),
    );

    final loaded = await patientRepository.getPatientForAuthUser('auth-user-2');
    expect(loaded?.firstName, 'Grace');
    expect(loaded?.lastName, 'Hopper');
    expect(writeCount, 1);

    final dirty = await db.patientsDao.getDirtyRows();
    expect(dirty, hasLength(1));
    expect(dirty.first.id, 'p-2');
    expect(dirty.first.isDirty, isTrue);
  });

  test('updatePreferences persists locally when offline', () async {
    final patient = await seedPatient(db, authUserId: 'auth-user-3', id: 'p-3');
    final now = DateTime.utc(2026, 7, 8, 8);
    final prefs = PatientPreferences(
      id: 'prefs-3',
      patientId: patient.id,
      createdAt: now,
      updatedAt: now,
    );
    await db.patientPreferencesDao.insertPreferences(prefs, isDirty: false);
    writeCount = 0;

    await patientRepository.updatePreferences(
      prefs.copyWith(weightUnit: 'lb', dailyWaterGoalMl: 1500),
    );

    final loaded =
        await patientRepository.getPreferencesForAuthUser('auth-user-3');
    expect(loaded?.weightUnit, 'lb');
    expect(loaded?.dailyWaterGoalMl, 1500);
    expect(writeCount, 1);

    final dirty = await db.patientPreferencesDao.getDirtyRows();
    expect(dirty, hasLength(1));
    expect(dirty.first.id, 'prefs-3');
    expect(dirty.first.isDirty, isTrue);
  });

  test('getPatientForAuthUser reads profile offline', () async {
    final patient = await seedPatient(db, authUserId: 'auth-user-4', id: 'p-4');
    final loaded = await patientRepository.getPatientForAuthUser('auth-user-4');
    expect(loaded?.id, patient.id);
  });

  test('vitals use client-generated UUID ids', () async {
    await seedPatient(db, authUserId: 'auth-user-1');

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
