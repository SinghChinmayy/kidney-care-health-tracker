import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/ui/features/vitals/models/blood_glucose_period.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
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

  test('periodChangeMgDl is newest minus oldest in period', () async {
    final now = DateTime.now().toUtc();
    await repo.addBloodGlucoseReading(
      BloodGlucoseReading(
        id: 'older',
        patientId: 'patient-1',
        recordedAt: now.subtract(const Duration(hours: 2)),
        valueMgDl: 100,
      ),
    );
    await repo.addBloodGlucoseReading(
      BloodGlucoseReading(
        id: 'newer',
        patientId: 'patient-1',
        recordedAt: now,
        valueMgDl: 125,
      ),
    );

    final viewModel = BloodGlucoseViewModel(vitalsRepository: repo);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await viewModel.refresh();
    viewModel.selectPeriod(BloodGlucosePeriod.last30Days);

    expect(viewModel.readings, hasLength(2));
    expect(viewModel.periodReadingCount, 2);
    expect(viewModel.periodChangeMgDl, closeTo(25, 0.001));
    expect(viewModel.heroValueMgDl, 125);
    expect(viewModel.periodAverageMgDl, closeTo(112.5, 0.001));
    expect(viewModel.periodMinMgDl, closeTo(100, 0.001));
    expect(viewModel.periodMaxMgDl, closeTo(125, 0.001));
    expect(viewModel.periodStdDevMgDl, isNotNull);
    expect(viewModel.chartDays, isNotEmpty);
  });

  test('changeVsPrevious compares to next older reading', () async {
    await repo.addBloodGlucoseReading(
      BloodGlucoseReading(
        id: 'older',
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 1, 10),
        valueMgDl: 100,
      ),
    );
    await repo.addBloodGlucoseReading(
      BloodGlucoseReading(
        id: 'newer',
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 2, 10),
        valueMgDl: 110,
      ),
    );

    final viewModel = BloodGlucoseViewModel(vitalsRepository: repo);
    await viewModel.refresh();

    final newest = viewModel.readings.first;
    expect(newest.id, 'newer');
    expect(viewModel.changeVsPrevious(newest), closeTo(10.0, 0.001));
    expect(viewModel.changeVsPrevious(viewModel.readings.last), isNull);
  });
}
