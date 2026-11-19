import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/active_patient_notifier.dart';
import 'package:app/data/repositories/sharing_repository.dart';
import 'package:app/data/services/patient_access_remote.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_member.dart';
import 'package:app/domain/models/patient_role.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_patient_access_remote.dart';

void main() {
  late AppDatabase db;
  late FakePatientAccessRemote remote;
  late ActivePatientNotifier notifier;
  late SharingRepository sharing;
  var syncRequests = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakePatientAccessRemote(me: 'me')
      ..usernames.addAll({'me': 'mia', 'owner': 'olga'});
    remote.addMember('p-1', 'owner', PatientRole.owner, isPatient: true);
    remote.addMember('p-1', 'me', PatientRole.caregiver);
    notifier = ActivePatientNotifier();
    syncRequests = 0;
    sharing = SharingRepository(
      db: db,
      remote: remote,
      currentAuthUserId: () => 'me',
      activePatientNotifier: notifier,
      requestSync: () => syncRequests++,
    );

    final now = DateTime.utc(2026, 11, 1);
    await db.patientsDao.insertPatient(
      Patient(id: 'p-1', firstName: 'Olga', createdAt: now, updatedAt: now),
      isDirty: false,
    );
    await db.patientAccessDao.upsertMembership(
      patientId: 'p-1',
      role: 'caregiver',
      updatedAt: now,
    );
    await db.bloodPressureDao.insertReading(
      BloodPressureReading(
        id: 'bp-1',
        patientId: 'p-1',
        recordedAt: now,
        systolic: 120,
        diastolic: 80,
      ),
      isDirty: false,
    );
  });

  tearDown(() => db.close());

  test('leaving evicts the patient locally right away', () async {
    await db.patientAccessDao.setSetting(activePatientSettingKey, 'p-1');

    await sharing.revokeAccess(patientId: 'p-1', userId: 'me');

    expect(remote.calls, contains('revoke:p-1:me'));
    expect(await db.patientsDao.getRowById('p-1'), isNull);
    expect(await db.bloodPressureDao.getRowById('bp-1'), isNull);
    expect(await db.patientAccessDao.getMembership('p-1'), isNull);
    expect(await db.patientAccessDao.getSetting(activePatientSettingKey),
        isNull);
    expect(notifier.revision, 1);
    expect(syncRequests, 1);
  });

  test('revoking someone else does not touch local data', () async {
    remote.members['p-1']!
      ..clear()
      ..add(const PatientMember(
        userId: 'me',
        role: PatientRole.owner,
        isPatient: false,
        username: 'mia',
      ))
      ..add(const PatientMember(
        userId: 'other',
        role: PatientRole.viewer,
        isPatient: false,
      ));

    await sharing.revokeAccess(patientId: 'p-1', userId: 'other');

    expect(await db.patientsDao.getRowById('p-1'), isNotNull);
    expect(notifier.revision, 0);
  });

  test('member handles are looked up once and cached', () async {
    expect(await sharing.memberHandle('p-1', 'owner'), '@olga');
    expect(await sharing.memberHandle('p-1', 'owner'), '@olga');
    expect(remote.calls.where((c) => c.startsWith('list:')), hasLength(1));
    expect(await sharing.memberHandle('p-1', 'stranger'), isNull);
  });

  test('server error codes become friendly messages', () {
    String messageFor(String key, {String? code}) => sharingExceptionFrom(
          PostgrestException(message: key, code: code),
        ).message;

    expect(messageFor('user_not_found'), 'No one has that username.');
    expect(messageFor('last_owner', code: '23514'),
        'A patient must always have at least one owner.');
    expect(messageFor('cannot_remove_patient_self'),
        "The patient's own account can't be removed.");
    expect(
      messageFor('duplicate key value violates unique constraint',
          code: '23505'),
      'That username is taken.',
    );
  });

  test('username validation mirrors the server rule', () {
    expect(validateUsername('ab'), isNotNull);
    expect(validateUsername('Mia_2026'), isNull, reason: 'normalized');
    expect(validateUsername('mia-2026'), isNotNull);
    expect(normalizeUsername('  MIA '), 'mia');
  });
}
