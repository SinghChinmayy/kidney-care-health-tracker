import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('patients dao inserts and reads active row', () async {
    const patient = Patient(
      id: 'patient-1',
      authUserId: 'auth-1',
      firstName: 'Ada',
      lastName: 'Lovelace',
    );

    await db.patientsDao.insertPatient(patient, isDirty: true);

    final loaded = await db.patientsDao.getActiveByAuthUserId('auth-1');
    expect(loaded, isNotNull);
    expect(loaded!.firstName, 'Ada');
    expect(loaded.lastName, 'Lovelace');
  });

  test('blood pressure dao inserts, queries active rows, and tracks dirty rows',
      () async {
    const patient = Patient(
      id: 'patient-1',
      authUserId: 'auth-1',
    );
    await db.patientsDao.insertPatient(patient, isDirty: false);

    final recordedAt = DateTime.utc(2026, 7, 7, 10);
    final reading = BloodPressureReading(
      id: const Uuid().v4(),
      patientId: patient.id,
      recordedAt: recordedAt,
      systolic: 120,
      diastolic: 80,
      heartRateBpm: 72,
      createdAt: recordedAt,
      updatedAt: recordedAt,
    );

    await db.bloodPressureDao.insertReading(reading, isDirty: true);

    final active = await db.bloodPressureDao.getActiveForPatient(patient.id);
    expect(active, hasLength(1));
    expect(active.first.systolic, 120);
    expect(active.first.diastolic, 80);

    final dirty = await db.bloodPressureDao.getDirtyRows();
    expect(dirty, hasLength(1));
    expect(dirty.first.isDirty, isTrue);
  });

  test('blood pressure dao soft delete hides row from active queries', () async {
    const patient = Patient(
      id: 'patient-1',
      authUserId: 'auth-1',
    );
    await db.patientsDao.insertPatient(patient, isDirty: false);

    const readingId = 'bp-1';
    final now = DateTime.utc(2026, 7, 7, 12);
    await db.bloodPressureDao.insertReading(
      BloodPressureReading(
        id: readingId,
        patientId: patient.id,
        recordedAt: now,
        systolic: 130,
        diastolic: 85,
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: false,
    );

    await db.bloodPressureDao.softDelete(readingId, now);

    final dirty = await db.bloodPressureDao.getDirtyRows();
    expect(dirty, hasLength(1));
    expect(dirty.first.id, readingId);
    expect(dirty.first.deletedAt, isNotNull);
    expect(dirty.first.isDirty, isTrue);
  });

  test('weight dao inserts and reads dialysis timing fields', () async {
    const patient = Patient(
      id: 'patient-1',
      authUserId: 'auth-1',
    );
    await db.patientsDao.insertPatient(patient, isDirty: false);

    final recordedAt = DateTime.utc(2026, 7, 7, 10);
    final reading = WeightReading(
      id: const Uuid().v4(),
      patientId: patient.id,
      recordedAt: recordedAt,
      valueKg: 72.5,
      dialysisTiming: dialysisTimingPostDialysis,
      weightContext: 'evening',
      createdAt: recordedAt,
      updatedAt: recordedAt,
    );

    await db.weightDao.insertReading(reading, isDirty: true);

    final active = await db.weightDao.getActiveForPatient(patient.id);
    expect(active, hasLength(1));
    expect(active.first.dialysisTiming, dialysisTimingPostDialysis);
    expect(active.first.weightContext, 'evening');
  });

  test('sync state dao stores pull cursor per table', () async {
    final pulledAt = DateTime.utc(2026, 7, 7, 9);

    await db.syncStateDao.setLastPulledAt(
      'blood_pressure_readings',
      pulledAt,
    );

    final loaded = await db.syncStateDao.getLastPulledAt(
      'blood_pressure_readings',
    );
    expect(loaded, isNotNull);
    expect(loaded!.toUtc(), pulledAt);
  });
}
