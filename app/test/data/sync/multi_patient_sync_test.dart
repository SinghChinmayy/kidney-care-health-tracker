import 'dart:convert';

import 'package:app/data/local/app_database.dart';
import 'package:app/data/sync/sync_engine.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_postgrest.dart';

const me = 'auth-me';

void main() {
  late AppDatabase db;
  late FakePostgrest server;
  late SyncEngine engine;
  late int accessChanges;

  void grant(String patientId, String role) {
    server.rows('patient_access').removeWhere(
          (r) => r['patient_id'] == patientId && r['user_id'] == me,
        );
    server.seed('patient_access', {
      'patient_id': patientId,
      'user_id': me,
      'role': role,
    });
  }

  void revoke(String patientId) {
    server.rows('patient_access').removeWhere(
          (r) => r['patient_id'] == patientId && r['user_id'] == me,
        );
  }

  void seedPatient(String id, {String? authUserId, String? firstName}) {
    server.seed('patients', {
      'id': id,
      'auth_user_id': authUserId,
      'first_name': firstName,
      'dialysis_type': 'none',
    });
  }

  void seedBp(String id, String patientId, {String? updatedAt}) {
    server.seed('blood_pressure_readings', {
      'id': id,
      'patient_id': patientId,
      'recorded_at': '2026-10-01T08:00:00Z',
      'systolic': 120,
      'diastolic': 80,
      'recorded_by': me,
      'updated_at': ?updatedAt,
    });
  }

  Future<List<String>> localBpIds(String patientId) async {
    final rows = await db.bloodPressureDao.getActiveForPatient(patientId);
    return rows.map((r) => r.id).toList()..sort();
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    server = FakePostgrest();
    accessChanges = 0;
    engine = SyncEngine(
      db: db,
      supabase: server.client(),
      currentAuthUserId: () => me,
      onAccessChanged: () => accessChanges++,
    );

    seedPatient('p-self', authUserId: me, firstName: 'Me');
    seedPatient('p-shared', firstName: 'Shared');
    grant('p-self', 'owner');
    grant('p-shared', 'caregiver');
    seedBp('bp-self', 'p-self');
    seedBp('bp-shared', 'p-shared');
  });

  tearDown(() => db.close());

  test('pulls every accessible patient with per-patient cursors', () async {
    final result = await engine.run();

    expect(result.isSuccess, isTrue, reason: '${result.failedTables}');
    expect(await localBpIds('p-self'), ['bp-self']);
    expect(await localBpIds('p-shared'), ['bp-shared']);
    expect(
      (await db.patientAccessDao.getMemberships())
          .map((m) => '${m.patientId}:${m.role}')
          .toSet(),
      {'p-self:owner', 'p-shared:caregiver'},
    );
    expect(
      await db.syncStateDao.getLastPulledAt('blood_pressure_readings:p-self'),
      isNotNull,
    );
    expect(accessChanges, 1);
  });

  test('new grant gets a full pull even when other cursors are ahead',
      () async {
    revoke('p-shared');
    // Old row for a patient not yet shared with us.
    seedPatient('p-new', firstName: 'New');
    seedBp('bp-old', 'p-new', updatedAt: '2026-01-01T00:00:00Z');
    await engine.run();
    expect(await localBpIds('p-new'), isEmpty);

    // More traffic on our own patient advances its cursor past bp-old.
    seedBp('bp-self-2', 'p-self');
    await engine.run();

    grant('p-new', 'viewer');
    await engine.run();

    expect(await localBpIds('p-new'), ['bp-old']);
    expect((await db.patientsDao.getActiveById('p-new'))?.firstName, 'New');
  });

  test('revocation evicts cached rows and resets the active patient',
      () async {
    await engine.run();
    await db.patientAccessDao.setSetting(activePatientSettingKey, 'p-shared');
    expect(await localBpIds('p-shared'), ['bp-shared']);
    accessChanges = 0;

    revoke('p-shared');
    final result = await engine.run();

    expect(result.isSuccess, isTrue);
    expect(await localBpIds('p-shared'), isEmpty);
    expect(await db.patientsDao.getRowById('p-shared'), isNull);
    expect(await db.patientAccessDao.getMembership('p-shared'), isNull);
    expect(
      await db.syncStateDao.getLastPulledAt('blood_pressure_readings:p-shared'),
      isNull,
    );
    expect(
      await db.patientAccessDao.getSetting(activePatientSettingKey),
      isNull,
    );
    expect(await localBpIds('p-self'), ['bp-self'], reason: 'others untouched');
    expect(accessChanges, 1);
  });

  test('viewer edits are never pushed and are discarded locally', () async {
    await engine.run();
    grant('p-shared', 'viewer');
    // A local edit made before the downgrade reached this device.
    await db.bloodPressureDao.insertReading(
      BloodPressureReading(
        id: 'bp-local',
        patientId: 'p-shared',
        recordedAt: DateTime.utc(2026, 11, 2),
        systolic: 150,
        diastolic: 95,
      ),
      isDirty: true,
    );
    server.requests.clear();

    final result = await engine.run();

    expect(result.isSuccess, isTrue);
    final posts = server.requests.where(
      (r) => r.method == 'POST' && r.url.path.endsWith('blood_pressure_readings'),
    );
    expect(posts, isEmpty);
    expect(await localBpIds('p-shared'), ['bp-shared'],
        reason: 'local edit discarded, server copy re-pulled');
  });

  test('caregiver edits push; patient pushes are PATCH without auth_user_id',
      () async {
    await engine.run();
    await db.bloodPressureDao.insertReading(
      BloodPressureReading(
        id: 'bp-care',
        patientId: 'p-shared',
        recordedAt: DateTime.utc(2026, 11, 2),
        systolic: 130,
        diastolic: 85,
      ),
      isDirty: true,
    );
    final shared = (await db.patientsDao.getActiveById('p-shared'))!;
    await db.patientsDao.updatePatient(
      shared.copyWithName('Renamed'),
      isDirty: true,
    );
    server.requests.clear();

    final result = await engine.run();

    expect(result.isSuccess, isTrue, reason: '${result.failedTables}');
    expect(
      server.rows('blood_pressure_readings').map((r) => r['id']),
      contains('bp-care'),
    );
    final patch = server.requests.singleWhere(
      (r) => r.method == 'PATCH' && r.url.path.endsWith('/patients'),
    );
    final body = jsonDecode(patch.body) as Map<String, dynamic>;
    expect(body.containsKey('auth_user_id'), isFalse);
    expect(body['first_name'], 'Renamed');
    expect(
      server.requests.where(
        (r) => r.method == 'POST' && r.url.path.endsWith('/patients'),
      ),
      isEmpty,
      reason: 'patients are never inserted by sync',
    );
  });
}

extension on Patient {
  Patient copyWithName(String firstName) => Patient(
        id: id,
        authUserId: authUserId,
        firstName: firstName,
        lastName: lastName,
        dialysisType: dialysisType,
        createdAt: createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
}
