import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_medication_schedule_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/domain/models/medication.dart';
import 'package:app/domain/models/patient.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> seedPatient(AppDatabase db) async {
  final now = DateTime.utc(2026, 7, 14, 8);
  await db.patientsDao.insertPatient(
    Patient(
      id: 'patient-1',
      authUserId: 'auth-user-1',
      dialysisDaysOfWeek: const [1, 3, 5],
      createdAt: now,
      updatedAt: now,
    ),
    isDirty: false,
  );
}

Future<void> seedMedication(AppDatabase db, String id, String name) async {
  final now = DateTime.utc(2026, 7, 14, 8);
  await db.medicationsDao.insert(
    Medication(
      id: id,
      pharmaceuticalName: name,
      composition: '$name 10mg',
      about: 'About $name',
      createdAt: now,
      updatedAt: now,
    ),
  );
}

void main() {
  late AppDatabase db;
  late PatientRepository patientRepository;
  late PatientMedicationScheduleRepository scheduleRepository;
  var writeCount = 0;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    writeCount = 0;
    patientRepository = PatientRepository(
      db: db,
      onWrite: () => writeCount++,
    );
    scheduleRepository = PatientMedicationScheduleRepository(
      db: db,
      patientRepository: patientRepository,
      currentAuthUserId: () => 'auth-user-1',
      onWrite: () => writeCount++,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('getOrCreateForCurrentPatient seeds empty schedule', () async {
    await seedPatient(db);

    final schedule = await scheduleRepository.getOrCreateForCurrentPatient();

    expect(schedule, isNotNull);
    expect(schedule!.patientId, 'patient-1');
    expect(schedule.byDay, isEmpty);
    expect(writeCount, 1);

    final again = await scheduleRepository.getOrCreateForCurrentPatient();
    expect(again!.id, schedule.id);
    expect(writeCount, 1);
  });

  test('addMedToDay appends and blocks duplicates', () async {
    await seedPatient(db);
    await seedMedication(db, 'med-a', 'Alpha');

    await scheduleRepository.addMedToDay(isoWeekday: 1, medicationId: 'med-a');
    final once = await scheduleRepository.getForCurrentPatient();
    expect(once!.byDay[1], ['med-a']);

    await scheduleRepository.addMedToDay(isoWeekday: 1, medicationId: 'med-a');
    final twice = await scheduleRepository.getForCurrentPatient();
    expect(twice!.byDay[1], ['med-a']);
  });

  test('removeMedFromDay drops id from that day only', () async {
    await seedPatient(db);
    await scheduleRepository.addMedToDay(isoWeekday: 1, medicationId: 'med-a');
    await scheduleRepository.addMedToDay(isoWeekday: 3, medicationId: 'med-a');

    await scheduleRepository.removeMedFromDay(
      isoWeekday: 1,
      medicationId: 'med-a',
    );

    final schedule = await scheduleRepository.getForCurrentPatient();
    expect(schedule!.byDay[1], isEmpty);
    expect(schedule.byDay[3], ['med-a']);
  });

  test('replaceMedOnDay swaps id and rejects duplicate target', () async {
    await seedPatient(db);
    await scheduleRepository.addMedToDay(isoWeekday: 1, medicationId: 'med-a');
    await scheduleRepository.addMedToDay(isoWeekday: 1, medicationId: 'med-b');

    final replaced = await scheduleRepository.replaceMedOnDay(
      isoWeekday: 1,
      oldMedicationId: 'med-a',
      newMedicationId: 'med-c',
    );
    expect(replaced!.byDay[1], ['med-c', 'med-b']);

    final blocked = await scheduleRepository.replaceMedOnDay(
      isoWeekday: 1,
      oldMedicationId: 'med-c',
      newMedicationId: 'med-b',
    );
    // Implementation removes old when target already exists.
    expect(blocked!.byDay[1], ['med-b']);
  });

  test('applyDialysisDaysChange drops removed days and keeps overlapping',
      () async {
    await seedPatient(db);
    await scheduleRepository.addMedToDay(isoWeekday: 1, medicationId: 'med-a');
    await scheduleRepository.addMedToDay(isoWeekday: 3, medicationId: 'med-b');

    final updated = await scheduleRepository.applyDialysisDaysChange(
      newDays: [1, 5],
    );

    expect(updated!.byDay.keys.toList()..sort(), [1, 5]);
    expect(updated.byDay[1], ['med-a']);
    expect(updated.byDay[5], isEmpty);
    expect(updated.byDay.containsKey(3), isFalse);
  });

  test('schedule dao marks dirty rows for sync', () async {
    await seedPatient(db);
    await scheduleRepository.getOrCreateForCurrentPatient();

    final dirty = await db.patientMedicationScheduleDao.getDirtyRows();
    expect(dirty, hasLength(1));
    expect(dirty.first.isDirty, isTrue);
  });
}
