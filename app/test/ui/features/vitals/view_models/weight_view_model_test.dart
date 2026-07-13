import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/ui/features/vitals/models/weight_period.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
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

  test('periodChangeKg is newest minus oldest in period', () async {
    final now = DateTime.now().toUtc();
    await repo.addWeightReading(
      WeightReading(
        id: 'older',
        patientId: 'patient-1',
        recordedAt: now.subtract(const Duration(hours: 2)),
        valueKg: 70,
      ),
    );
    await repo.addWeightReading(
      WeightReading(
        id: 'newer',
        patientId: 'patient-1',
        recordedAt: now,
        valueKg: 72.5,
      ),
    );

    final stored = await repo.getWeightReadings();
    expect(stored, hasLength(2));

    final viewModel = WeightViewModel(vitalsRepository: repo);
    // Let constructor refresh finish before asserting.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await viewModel.refresh();
    viewModel.selectPeriod(WeightPeriod.last30Days);

    expect(viewModel.readings, hasLength(2));
    expect(viewModel.periodReadingCount, 2);
    expect(viewModel.periodChangeKg, closeTo(2.5, 0.001));
    expect(viewModel.heroWeightKg, 72.5);
    expect(viewModel.periodAverageKg, closeTo(71.25, 0.001));
    expect(viewModel.chartDays, isNotEmpty);
  });

  test('changeVsPrevious compares to next older reading', () async {
    await repo.addWeightReading(
      WeightReading(
        id: 'older',
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 1, 10),
        valueKg: 70,
      ),
    );
    await repo.addWeightReading(
      WeightReading(
        id: 'newer',
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 2, 10),
        valueKg: 71,
      ),
    );

    final viewModel = WeightViewModel(vitalsRepository: repo);
    await viewModel.refresh();

    final newest = viewModel.readings.first;
    expect(newest.id, 'newer');
    expect(viewModel.changeVsPrevious(newest), closeTo(1.0, 0.001));
    expect(viewModel.changeVsPrevious(viewModel.readings.last), isNull);
  });
}
