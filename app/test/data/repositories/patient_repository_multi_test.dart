import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/active_patient_notifier.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/data/services/patient_access_remote.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_role.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const me = 'auth-me';

class _FakeRemote implements PatientAccessRemote {
  final calls = <Map<String, Object?>>[];

  @override
  Future<Map<String, dynamic>> createPatient({
    required String id,
    required String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? sex,
    String? bloodGroup,
  }) async {
    calls.add({'id': id, 'first': firstName, 'blood': bloodGroup});
    return {
      'id': id,
      'auth_user_id': null,
      'first_name': firstName,
      'last_name': lastName,
      'blood_group': bloodGroup,
      'dialysis_type': 'none',
      'created_at': '2026-11-12T09:00:00Z',
      'updated_at': '2026-11-12T09:00:00Z',
    };
  }
}

void main() {
  late AppDatabase db;
  late ActivePatientNotifier notifier;
  late _FakeRemote remote;
  late PatientRepository patients;
  late VitalsRepository vitals;
  var writes = 0;

  Future<void> addPatient(String id, {String? authUserId, String? name}) {
    final now = DateTime.utc(2026, 11, 1);
    return db.patientsDao.insertPatient(
      Patient(
        id: id,
        authUserId: authUserId,
        firstName: name,
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: false,
    );
  }

  Future<void> member(String patientId, PatientRole role) {
    return db.patientAccessDao.upsertMembership(
      patientId: patientId,
      role: role.wire,
      updatedAt: DateTime.utc(2026, 11, 1),
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notifier = ActivePatientNotifier();
    remote = _FakeRemote();
    writes = 0;
    patients = PatientRepository(
      db: db,
      remote: remote,
      activePatientNotifier: notifier,
      onWrite: () => writes++,
    );
    vitals = VitalsRepository(
      db: db,
      patientRepository: patients,
      currentAuthUserId: () => me,
    );
    await addPatient('p-self', authUserId: me, name: 'Me');
    await addPatient('p-mum', name: 'Mum');
    await addPatient('p-dad', name: 'Dad');
    await member('p-self', PatientRole.owner);
    await member('p-mum', PatientRole.caregiver);
    await member('p-dad', PatientRole.viewer);
  });

  tearDown(() => db.close());

  test('active patient defaults to self and persists a switch', () async {
    expect((await patients.getActivePatient(me))!.id, 'p-self');

    await patients.setActivePatient('p-mum');

    expect(notifier.revision, 1);
    expect((await patients.getActivePatient(me))!.id, 'p-mum');
    expect(await patients.getActiveRole(me), PatientRole.caregiver);
  });

  test('stale active pick (revoked) falls back to self', () async {
    await patients.setActivePatient('p-mum');
    await db.evictPatient('p-mum');

    expect((await patients.getActivePatient(me))!.id, 'p-self');
  });

  test('lists self first, then others alphabetically with roles', () async {
    final list = await patients.listAccessiblePatients(me);
    expect(
      list.map((p) => '${p.displayName}:${p.role.name}:${p.isSelf}'),
      ['Me:owner:true', 'Dad:viewer:false', 'Mum:caregiver:false'],
    );
  });

  test('vitals follow the active patient', () async {
    await patients.setActivePatient('p-mum');
    await vitals.addBloodPressureReading(
      BloodPressureReading(
        id: 'bp-1',
        recordedAt: DateTime.utc(2026, 11, 2),
        systolic: 120,
        diastolic: 80,
      ),
    );

    expect((await db.bloodPressureDao.getRowById('bp-1'))!.patientId, 'p-mum');
    expect(await vitals.getBloodPressureReadings(), hasLength(1));

    await patients.setActivePatient('p-self');
    expect(await vitals.getBloodPressureReadings(), isEmpty);
  });

  test('viewers cannot write vitals, profile or preferences', () async {
    await patients.setActivePatient('p-dad');

    expect(await vitals.canWriteCurrentPatient(), isFalse);
    await expectLater(
      vitals.addBloodPressureReading(
        BloodPressureReading(
          id: 'bp-x',
          recordedAt: DateTime.utc(2026, 11, 2),
          systolic: 120,
          diastolic: 80,
        ),
      ),
      throwsA(isA<ReadOnlyPatientException>()),
    );
    final dad = (await patients.getActivePatient(me))!;
    await expectLater(
      patients.updateProfile(dad, authUserId: me),
      throwsA(isA<ReadOnlyPatientException>()),
    );
    expect(
      await patients.getOrCreatePreferencesForPatient('p-dad', authUserId: me),
      isNull,
      reason: 'viewers never seed local rows',
    );
    expect(await db.patientsDao.getDirtyRows(), isEmpty);
  });

  test('createPatient caches the server row as owner and activates it',
      () async {
    final created = await patients.createPatient(
      firstName: ' Gran ',
      bloodGroup: 'B+',
    );

    expect(remote.calls.single['first'], 'Gran');
    expect(created.firstName, 'Gran');
    expect(created.bloodGroup, 'B+');
    expect(created.authUserId, isNull);
    expect((await db.patientAccessDao.getMembership(created.id))!.role, 'owner');
    expect((await patients.getActivePatient(me))!.id, created.id);
    expect(writes, 1, reason: 'schedules a sync to pull bootstrapped prefs');
  });
}
