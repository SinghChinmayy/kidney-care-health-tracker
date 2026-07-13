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
  return ChangeNotifierProvider(
    create: (_) => WeightViewModel(vitalsRepository: vitalsRepository),
    child: MaterialApp(
      theme: AppTheme.light,
      home: const WeightView(),
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
      ),
      currentAuthUserId: () => 'auth-1',
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('renders activity-style weight page', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('W'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('TRACK'), findsNothing);
    expect(find.text('HISTORY'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Log'), findsOneWidget);
  });

  testWidgets('add opens log sheet and save persists reading', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Log weight'), findsWidgets);
    expect(find.text('Day type'), findsOneWidget);

    final fields = find.byType(TextField);
    expect(fields, findsWidgets);
    await tester.enterText(fields.first, '85');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Weight saved'), findsOneWidget);

    final readings = await vitalsRepository.getWeightReadings();
    expect(readings, hasLength(1));
    expect(readings.first.valueKg, 85.0);
    expect(readings.first.dialysisTiming, dialysisTimingNonDialysis);
  });

  testWidgets('Recent shows readings and opens edit sheet', (tester) async {
    const readingId = 'weight-edit-1';
    await vitalsRepository.addWeightReading(
      WeightReading(
        id: readingId,
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc(),
        valueKg: 72.5,
        dialysisTiming: dialysisTimingPreDialysis,
        weightContext: weightContextMorning,
      ),
    );

    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Morning'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Edit weight'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
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
        recordedAt: DateTime.now().toUtc(),
        valueKg: 72.5,
      ),
    );

    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete reading'));
    await tester.tap(find.text('Delete reading'));
    await tester.pumpAndSettle();

    expect(find.text('Delete reading?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Weight deleted'), findsOneWidget);

    final readings = await vitalsRepository.getWeightReadings();
    expect(readings, isEmpty);
  });

  testWidgets('period chips switch labels', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    expect(find.text('This Month'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('All Time'), findsOneWidget);
  });

  testWidgets('week chevrons move between weeks', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    expect(find.text('This Week'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();

    expect(find.text('This Week'), findsNothing);

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.text('This Week'), findsOneWidget);
  });

  testWidgets('month chevrons move between months', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    expect(find.text('This Month'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('This Month'), findsNothing);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('This Month'), findsOneWidget);
  });

  testWidgets('year chevrons move between years', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Y'));
    await tester.pumpAndSettle();
    expect(find.text('This Year'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous year'));
    await tester.pumpAndSettle();
    expect(find.text('This Year'), findsNothing);

    await tester.tap(find.byTooltip('Next year'));
    await tester.pumpAndSettle();
    expect(find.text('This Year'), findsOneWidget);
  });

  testWidgets('seeded history appears in Recent without tabs', (tester) async {
    await vitalsRepository.addWeightReading(
      WeightReading(
        id: const Uuid().v4(),
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        valueKg: 71.0,
      ),
    );

    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Yesterday'));
    await tester.pumpAndSettle();
    expect(find.text('71.0'), findsWidgets);
    expect(find.text('Yesterday'), findsOneWidget);
  });
}
