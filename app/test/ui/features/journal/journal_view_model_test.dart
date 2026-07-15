import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/medications_repository.dart';
import 'package:app/data/repositories/patient_medication_schedule_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/medication.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:app/ui/features/journal/view_models/journal_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late JournalViewModel viewModel;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.utc(2026, 7, 14, 8);
    await db.patientsDao.insertPatient(
      Patient(
        id: 'patient-1',
        authUserId: 'auth-1',
        dialysisDaysOfWeek: const [1, 3],
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: false,
    );
    await db.medicationsDao.insert(
      Medication(
        id: 'med-z',
        pharmaceuticalName: 'Zed Med',
        composition: 'Z',
        about: 'Z about',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.medicationsDao.insert(
      Medication(
        id: 'med-a',
        pharmaceuticalName: 'Alpha Med',
        composition: 'A',
        about: 'A about',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.weightDao.insertReading(
      WeightReading(
        id: 'w1',
        patientId: 'patient-1',
        recordedAt: now,
        valueKg: 70.5,
        dialysisTiming: dialysisTimingPostDialysis,
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: false,
    );

    final patients = PatientRepository(db: db);
    final vitals = VitalsRepository(
      db: db,
      patientRepository: patients,
      currentAuthUserId: () => 'auth-1',
    );
    final meds = MedicationsRepository(db: db);
    // Skip seed overwrite by ensuring count > 0 already.
    final schedule = PatientMedicationScheduleRepository(
      db: db,
      patientRepository: patients,
      currentAuthUserId: () => 'auth-1',
    );

    viewModel = JournalViewModel(
      vitalsRepository: vitals,
      medicationsRepository: meds,
      scheduleRepository: schedule,
    );
    await Future<void>.delayed(Duration.zero);
    await viewModel.refresh();
  });

  tearDown(() async {
    viewModel.dispose();
    await db.close();
  });

  test('loads dry weight from latest post-dialysis reading', () {
    expect(viewModel.dryWeight, isNotNull);
    expect(viewModel.dryWeightLabel, '70.5 kg');
  });

  test('medsForDaySorted orders by pharmaceutical name A-Z', () async {
    await viewModel.addMedToDay(isoWeekday: 1, medicationId: 'med-z');
    await viewModel.addMedToDay(isoWeekday: 1, medicationId: 'med-a');

    final meds = viewModel.medsForDaySorted(1);
    expect(meds.map((m) => m.id).toList(), ['med-a', 'med-z']);
  });

  test('addMedToDay returns false for duplicate', () async {
    final first = await viewModel.addMedToDay(
      isoWeekday: 1,
      medicationId: 'med-a',
    );
    final second = await viewModel.addMedToDay(
      isoWeekday: 1,
      medicationId: 'med-a',
    );

    expect(first, isTrue);
    expect(second, isFalse);
  });

  test('weekday helpers', () {
    expect(weekdayFullLabel(1), 'Monday');
    expect(dialysisDayOrdinalLabel(0), 'First day of dialysis');
    expect(dialysisDayOrdinalLabel(1), '2nd day of dialysis');
  });
}
