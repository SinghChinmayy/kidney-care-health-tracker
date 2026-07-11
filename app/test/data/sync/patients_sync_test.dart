import 'package:app/data/local/app_database.dart';
import 'package:app/data/sync/sync_utils.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('reconcilePatientId rewrites vitals FK to server patient id', () async {
    await db.patientsDao.upsertRemoteRow(
      PatientRow(
        id: 'local-patient',
        authUserId: 'auth-1',
        firstName: null,
        lastName: null,
        dateOfBirth: null,
        sex: null,
        ckdStage: null,
        dialysisType: 'none',
        dialysisDaysOfWeek: null,
        heightCm: null,
        createdAt: DateTime.utc(2026, 7, 8, 9),
        updatedAt: DateTime.utc(2026, 7, 8, 9),
        deletedAt: null,
        isDirty: true,
      ),
      isDirty: true,
    );

    await db.bloodPressureDao.insertReading(
      BloodPressureReading(
        id: 'bp-1',
        patientId: 'local-patient',
        recordedAt: DateTime.utc(2026, 7, 8, 10),
        systolic: 120,
        diastolic: 80,
        createdAt: DateTime.utc(2026, 7, 8, 10),
        updatedAt: DateTime.utc(2026, 7, 8, 10),
      ),
      isDirty: true,
    );

    await db.reconcilePatientId(
      oldPatientId: 'local-patient',
      newPatientId: 'server-patient',
    );

    final bp = await db.bloodPressureDao.getRowById('bp-1');
    expect(bp!.patientId, 'server-patient');
    expect(await db.patientsDao.getRowById('local-patient'), isNull);
    expect(await db.patientsDao.getRowById('server-patient'), isNotNull);
  });

  test('LWW keeps dirty local row when remote is older', () async {
    final localUpdatedAt = DateTime.utc(2026, 7, 8, 12);
    final remoteUpdatedAt = DateTime.utc(2026, 7, 8, 11);

    await db.bloodPressureDao.upsertRemoteRow(
      BloodPressureRow(
        id: 'bp-1',
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 8, 10),
        systolic: 130,
        diastolic: 85,
        heartRateBpm: null,
        notes: null,
        createdAt: DateTime.utc(2026, 7, 8, 10),
        updatedAt: localUpdatedAt,
        deletedAt: null,
        isDirty: true,
      ),
      isDirty: true,
    );

    expect(
      shouldApplyRemoteUpdate(
        remoteUpdatedAt: remoteUpdatedAt,
        localUpdatedAt: localUpdatedAt,
      ),
      isFalse,
    );

    final local = await db.bloodPressureDao.getRowById('bp-1');
    expect(local!.systolic, 130);
    expect(local.isDirty, isTrue);
  });
}
