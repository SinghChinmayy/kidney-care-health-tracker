import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/views/weight_view.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

Future<void> seedWeightPatient(AppDatabase db) async {
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
}

Widget buildWeightView({
  required VitalsRepository vitalsRepository,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: ChangeNotifierProvider(
      create: (_) => WeightViewModel(vitalsRepository: vitalsRepository),
      child: const WeightView(),
    ),
  );
}

void main() {
  late AppDatabase db;
  late VitalsRepository vitalsRepository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedWeightPatient(db);
    vitalsRepository = VitalsRepository(
      db: db,
      patientRepository: PatientRepository(
        db: db,
        isOnline: () async => false,
      ),
      currentAuthUserId: () => 'auth-1',
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('renders Track and History tabs', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    expect(find.text('TRACK'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('WEIGHT (KG)'), findsOneWidget);
    expect(find.text('WHEN'), findsOneWidget);
  });

  testWidgets('Save persists a reading from Track tab', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    expect(find.text('70.0'), findsOneWidget);

    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final readings = await vitalsRepository.getWeightReadings();
    expect(readings, hasLength(1));
    expect(readings.first.valueKg, 70.0);
  });

  testWidgets('History shows grouped date headers', (tester) async {
    await vitalsRepository.addWeightReading(
      WeightReading(
        id: const Uuid().v4(),
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 7, 10),
        valueKg: 72.5,
      ),
    );
    await vitalsRepository.addWeightReading(
      WeightReading(
        id: const Uuid().v4(),
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 6, 18),
        valueKg: 71.0,
      ),
    );

    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();

    expect(find.text('TUESDAY, JULY 7'), findsOneWidget);
    expect(find.text('MONDAY, JULY 6'), findsOneWidget);
    expect(find.text('72.5 kg'), findsOneWidget);
    expect(find.text('71.0 kg'), findsOneWidget);
  });
}
