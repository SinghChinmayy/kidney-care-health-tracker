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
    viewModel.selectPeriod(BloodPressurePeriod.last30Days);

    expect(viewModel.readings, hasLength(2));
    expect(viewModel.periodReadingCount, 2);
    expect(viewModel.periodChangeSystolic, 25);
    expect(viewModel.heroDisplayValue, '125/80');
    expect(viewModel.periodAverageSystolic, closeTo(112.5, 0.001));
    expect(viewModel.periodAverageDisplay, '113/75');
    expect(viewModel.periodRangeDisplay, '100–125 / 70–80');
    expect(viewModel.heroSubtitle, contains('avg 113/75'));
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

  group('systolic min/max/avg', () {
    test('returns correct values with multiple readings', () async {
      final now = DateTime.now().toUtc();
      for (final sys in [100, 120, 140]) {
        await repo.addBloodPressureReading(
          BloodPressureReading(
            id: 'sys-$sys',
            patientId: 'patient-1',
            recordedAt: now.subtract(Duration(hours: sys)),
            systolic: sys,
            diastolic: sys - 30,
          ),
        );
      }

      final vm = BloodPressureViewModel(vitalsRepository: repo);
      await vm.refresh();
      vm.selectPeriod(BloodPressurePeriod.last30Days);

      expect(vm.periodMinSystolic, 100);
      expect(vm.periodMaxSystolic, 140);
      expect(vm.periodAverageSystolic, closeTo(120.0, 0.001));
    });

    test('returns null when no systolic readings in period', () async {
      await repo.addBloodPressureReading(
        BloodPressureReading(
          id: 'hr-only',
          patientId: 'patient-1',
          recordedAt: DateTime.now().toUtc(),
          heartRateBpm: 72,
        ),
      );

      final vm = BloodPressureViewModel(vitalsRepository: repo);
      await vm.refresh();
      vm.selectPeriod(BloodPressurePeriod.last30Days);

      expect(vm.periodMinSystolic, isNull);
      expect(vm.periodMaxSystolic, isNull);
      expect(vm.periodAverageSystolic, isNull);
    });
  });

  group('diastolic min/max/avg', () {
    test('returns correct values with multiple readings', () async {
      final now = DateTime.now().toUtc();
      final diastolics = [70, 80, 90];
      for (var i = 0; i < diastolics.length; i++) {
        await repo.addBloodPressureReading(
          BloodPressureReading(
            id: 'dia-$i',
            patientId: 'patient-1',
            recordedAt: now.subtract(Duration(hours: i + 1)),
            systolic: 120,
            diastolic: diastolics[i],
          ),
        );
      }

      final vm = BloodPressureViewModel(vitalsRepository: repo);
      await vm.refresh();
      vm.selectPeriod(BloodPressurePeriod.last30Days);

      expect(vm.periodMinDiastolic, 70);
      expect(vm.periodMaxDiastolic, 90);
      expect(vm.periodAverageDiastolic, closeTo(80.0, 0.001));
    });

    test('returns null when period has no readings', () async {
      final vm = BloodPressureViewModel(vitalsRepository: repo);
      await vm.refresh();
      vm.selectPeriod(BloodPressurePeriod.last30Days);

      expect(vm.periodMinDiastolic, isNull);
      expect(vm.periodMaxDiastolic, isNull);
      expect(vm.periodAverageDiastolic, isNull);
    });
  });

  group('heart rate min/max/avg', () {
    test('returns correct values from readings with heartRateBpm', () async {
      final now = DateTime.now().toUtc();
      final hrs = [60, 75, 90];
      for (var i = 0; i < hrs.length; i++) {
        await repo.addBloodPressureReading(
          BloodPressureReading(
            id: 'hr-$i',
            patientId: 'patient-1',
            recordedAt: now.subtract(Duration(hours: i + 1)),
            heartRateBpm: hrs[i],
          ),
        );
      }

      final vm = BloodPressureViewModel(vitalsRepository: repo);
      await vm.refresh();
      vm.selectPeriod(BloodPressurePeriod.last30Days);

      expect(vm.periodMinHr, 60);
      expect(vm.periodMaxHr, 90);
      expect(vm.periodAverageHr, closeTo(75.0, 0.001));
    });

    test('returns null when no HR readings in period', () async {
      await repo.addBloodPressureReading(
        BloodPressureReading(
          id: 'bp-only',
          patientId: 'patient-1',
          recordedAt: DateTime.now().toUtc(),
          systolic: 120,
          diastolic: 80,
        ),
      );

      final vm = BloodPressureViewModel(vitalsRepository: repo);
      await vm.refresh();
      vm.selectPeriod(BloodPressurePeriod.last30Days);

      expect(vm.periodMinHr, isNull);
      expect(vm.periodMaxHr, isNull);
      expect(vm.periodAverageHr, isNull);
    });

    test('chartDays includes heartRateBpm values', () async {
      final now = DateTime.now().toUtc();
      await repo.addBloodPressureReading(
        BloodPressureReading(
          id: 'hr-chart',
          patientId: 'patient-1',
          recordedAt: now,
          systolic: 120,
          diastolic: 80,
          heartRateBpm: 68,
        ),
      );

      final vm = BloodPressureViewModel(vitalsRepository: repo);
      await vm.refresh();
      vm.selectPeriod(BloodPressurePeriod.last30Days);

      final todayBucket = vm.chartDays.lastWhere(
        (d) => d.heartRateBpm != null,
        orElse: () => throw StateError('No HR bucket found'),
      );
      expect(todayBucket.heartRateBpm, 68);
      expect(todayBucket.diastolic, 80);
    });
  });

  group('standard deviation', () {
    test('calculates correct values for systolic and diastolic', () async {
      final now = DateTime.now().toUtc();
      // seed readings with systolic 110, 120, 130 (avg = 120, stddev = sqrt(((110-120)^2 + 0 + (130-120)^2)/3) = sqrt(200/3) = sqrt(66.67) ~ 8.16)
      // seed diastolic 70, 80, 90 (avg = 80, stddev = sqrt(200/3) ~ 8.16)
      for (var i = 0; i < 3; i++) {
        await repo.addBloodPressureReading(
          BloodPressureReading(
            id: 'stddev-$i',
            patientId: 'patient-1',
            recordedAt: now.subtract(Duration(hours: i + 1)),
            systolic: 110 + i * 10,
            diastolic: 70 + i * 10,
          ),
        );
      }

      final vm = BloodPressureViewModel(vitalsRepository: repo);
      await vm.refresh();
      vm.selectPeriod(BloodPressurePeriod.last30Days);

      expect(vm.periodStdDevSystolic, closeTo(8.165, 0.01));
      expect(vm.periodStdDevDiastolic, closeTo(8.165, 0.01));
    });
  });
}
