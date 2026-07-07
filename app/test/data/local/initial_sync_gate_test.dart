import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/patient.dart';
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

  test('hasLocalDataForAuthUser returns true when patient row exists', () async {
    await db.patientsDao.insertPatient(
      Patient(
        id: 'patient-1',
        authUserId: 'auth-1',
        createdAt: DateTime.utc(2026, 7, 8, 10),
        updatedAt: DateTime.utc(2026, 7, 8, 10),
      ),
      isDirty: false,
    );

    expect(await db.hasLocalDataForAuthUser('auth-1'), isTrue);
    expect(await db.hasLocalDataForAuthUser('other-auth'), isFalse);
  });

  test('wipeAllData clears patient rows for fresh login sync gate', () async {
    await db.patientsDao.insertPatient(
      Patient(
        id: 'patient-1',
        authUserId: 'auth-1',
        createdAt: DateTime.utc(2026, 7, 8, 10),
        updatedAt: DateTime.utc(2026, 7, 8, 10),
      ),
      isDirty: false,
    );

    await db.wipeAllData();

    expect(await db.hasLocalDataForAuthUser('auth-1'), isFalse);
  });
}
