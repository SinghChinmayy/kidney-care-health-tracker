import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';
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
    expect(find.text('DIALYSIS TIMING'), findsNothing);
    expect(find.text('DAY TYPE'), findsOneWidget);
    expect(find.text('WHEN'), findsOneWidget);
  });

  testWidgets('Save persists typed weight without pressing enter', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '85');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final readings = await vitalsRepository.getWeightReadings();
    expect(readings, hasLength(1));
    expect(readings.first.valueKg, 85.0);
  });

  testWidgets('Save persists a reading from Track tab', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    expect(find.text('70.0'), findsOneWidget);

    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    expect(find.text('Weight saved'), findsOneWidget);

    final readings = await vitalsRepository.getWeightReadings();
    expect(readings, hasLength(1));
    expect(readings.first.valueKg, 70.0);
    expect(readings.first.dialysisTiming, dialysisTimingNonDialysis);
  });

  testWidgets('can save pre-dialysis reading from timing picker', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    expect(find.text('DAY TYPE'), findsOneWidget);
    expect(find.text('Pre-dialysis'), findsNothing);

    await tester.tap(find.text('Dialysis day'));
    await tester.pumpAndSettle();

    expect(find.text('TIMING'), findsOneWidget);
    expect(find.text('Pre-dialysis'), findsOneWidget);

    await tester.ensureVisible(find.text('SAVE'));
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final readings = await vitalsRepository.getWeightReadings();
    expect(readings, hasLength(1));
    expect(readings.first.dialysisTiming, dialysisTimingPreDialysis);
  });

  testWidgets('History shows grouped date headers', (tester) async {
    await vitalsRepository.addWeightReading(
      WeightReading(
        id: const Uuid().v4(),
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 7, 10),
        valueKg: 72.5,
        dialysisTiming: dialysisTimingPreDialysis,
        weightContext: 'morning',
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
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Pre-dialysis'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('Edit updates reading when tapping history row', (tester) async {
    const readingId = 'weight-edit-1';
    await vitalsRepository.addWeightReading(
      WeightReading(
        id: readingId,
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 7, 10),
        valueKg: 72.5,
      ),
    );

    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('72.5 kg'));
    await tester.pumpAndSettle();

    expect(find.text('Edit weight'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('SAVE CHANGES'));
    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pumpAndSettle();

    expect(find.text('Weight updated'), findsOneWidget);

    final readings = await vitalsRepository.getWeightReadings();
    expect(readings, hasLength(1));
    expect(readings.first.id, readingId);
    expect(readings.first.valueKg, 73.0);
  });

  testWidgets('Delete removes reading from edit sheet', (tester) async {
    const readingId = 'weight-delete-1';
    await vitalsRepository.addWeightReading(
      WeightReading(
        id: readingId,
        patientId: 'patient-1',
        recordedAt: DateTime.utc(2026, 7, 7, 10),
        valueKg: 72.5,
      ),
    );

    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('72.5 kg'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete reading'));
    await tester.tap(find.text('Delete reading'));
    await tester.pumpAndSettle();

    expect(find.text('Delete reading?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Weight deleted'), findsOneWidget);
    expect(find.text('72.5 kg'), findsNothing);

    final readings = await vitalsRepository.getWeightReadings();
    expect(readings, isEmpty);
  });
}
