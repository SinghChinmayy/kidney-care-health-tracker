import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/ui/features/vitals/models/fluid_intake_period.dart';
import 'package:app/ui/features/vitals/view_models/fluid_intake_view_model.dart';
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

  test('period daily stats use summed day totals', () async {
    final now = DateTime.now().toUtc();
    await repo.addFluidIntakeLog(
      FluidIntakeLog(
        id: 'a',
        patientId: 'patient-1',
        recordedAt: now.subtract(const Duration(hours: 2)),
        fluidMl: 200,
      ),
    );
    await repo.addFluidIntakeLog(
      FluidIntakeLog(
        id: 'b',
        patientId: 'patient-1',
        recordedAt: now,
        fluidMl: 300,
      ),
    );

    final viewModel = FluidIntakeViewModel(vitalsRepository: repo);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await viewModel.refresh();
    viewModel.selectPeriod(FluidIntakePeriod.last30Days);

    expect(viewModel.logs, hasLength(2));
    expect(viewModel.periodLogCount, 2);
    expect(viewModel.periodAverageDailyMl, closeTo(500, 0.001));
    expect(viewModel.heroTotalMl, closeTo(500, 0.001));
    expect(viewModel.chartDays, isNotEmpty);
  });

  test('changeVsPrevious compares to next older log', () async {
    await repo.addFluidIntakeLog(
      FluidIntakeLog(
        id: 'older',
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 1, 10),
        fluidMl: 200,
      ),
    );
    await repo.addFluidIntakeLog(
      FluidIntakeLog(
        id: 'newer',
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 2, 10),
        fluidMl: 250,
      ),
    );

    final viewModel = FluidIntakeViewModel(vitalsRepository: repo);
    await viewModel.refresh();

    final newest = viewModel.logs.first;
    expect(newest.id, 'newer');
    expect(viewModel.changeVsPrevious(newest), closeTo(50.0, 0.001));
    expect(viewModel.changeVsPrevious(viewModel.logs.last), isNull);
  });

  test('update and delete log refresh list', () async {
    await repo.addFluidIntakeLog(
      FluidIntakeLog(
        id: 'keep',
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 2, 10),
        fluidMl: 200,
      ),
    );

    final viewModel = FluidIntakeViewModel(vitalsRepository: repo);
    await viewModel.refresh();
    final existing = viewModel.logs.first;

    await viewModel.updateLog(
      existing: existing,
      fluidMl: 350,
      recordedAt: existing.recordedAt.toLocal(),
    );
    expect(viewModel.logs.first.fluidMl, 350);

    await viewModel.deleteLog(existing.id);
    expect(viewModel.logs, isEmpty);
  });
}
