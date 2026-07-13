import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/ui/features/vitals/models/blood_pressure_period.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late VitalsRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.utc(2026, 7, 8, 8);
    await db.patientsDao.insertPatient(
      Patient(
        id: 'patient-1',
        authUserId: 'auth-1',
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: false,
    );
    repo = VitalsRepository(
      db: db,
      patientRepository: PatientRepository(db: db),
      currentAuthUserId: () => 'auth-1',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('periodChangeSystolic is newest minus oldest in period', () async {
    final now = DateTime.now().toUtc();
    await repo.addBloodPressureReading(
      BloodPressureReading(
        id: 'older',
        patientId: 'patient-1',
        recordedAt: now.subtract(const Duration(hours: 2)),
        systolic: 100,
        diastolic: 70,
      ),
    );
    await repo.addBloodPressureReading(
      BloodPressureReading(
        id: 'newer',
        patientId: 'patient-1',
        recordedAt: now,
        systolic: 125,
        diastolic: 80,
      ),
    );

    final viewModel = BloodPressureViewModel(vitalsRepository: repo);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await viewModel.refresh();
    viewModel.selectPeriod(BloodPressurePeriod.all);

    expect(viewModel.readings, hasLength(2));
    expect(viewModel.periodReadingCount, 2);
    expect(viewModel.periodChangeSystolic, 25);
    expect(viewModel.heroDisplayValue, '125/80');
    expect(viewModel.periodAverageSystolic, closeTo(112.5, 0.001));
    expect(viewModel.chartDays, isNotEmpty);
  });

  test('changeVsPrevious compares to next older systolic reading', () async {
    await repo.addBloodPressureReading(
      BloodPressureReading(
        id: 'older',
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 1, 10),
        systolic: 100,
        diastolic: 70,
      ),
    );
    await repo.addBloodPressureReading(
      BloodPressureReading(
        id: 'newer',
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 2, 10),
        systolic: 110,
        diastolic: 75,
      ),
    );

    final viewModel = BloodPressureViewModel(vitalsRepository: repo);
    await viewModel.refresh();

    final newest = viewModel.readings.first;
    expect(newest.id, 'newer');
    expect(viewModel.changeVsPrevious(newest), 10);
    expect(viewModel.changeVsPrevious(viewModel.readings.last), isNull);
  });
}
