import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/views/weight_view.dart';
import 'package:app/ui/features/vitals/widgets/weight_recent_card.dart';
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

    expect(find.text('Weight'), findsWidgets);
    expect(find.text('7D'), findsOneWidget);
    expect(find.text('30D'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Last 7 Days'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Graph'), findsOneWidget);
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
    expect(find.text('When'), findsOneWidget);

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

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('This Month'), findsOneWidget);

    await tester.tap(find.text('30D'));
    await tester.pumpAndSettle();
    expect(find.text('Last 30 Days'), findsOneWidget);
  });

  testWidgets('month chevrons move between months', (tester) async {
    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('This Month'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('This Month'), findsNothing);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('This Month'), findsOneWidget);
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

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final sameWeek =
        weekStartForLocalDate(today) == weekStartForLocalDate(yesterday);
    if (sameWeek) {
      expect(find.text('This Week'), findsAtLeastNWidgets(1));
    } else {
      expect(find.text('Last Week'), findsOneWidget);
    }
  });

  testWidgets('shows max 3 readings per week and a N-more row', (tester) async {
    final now = DateTime.now().toUtc();
    for (var i = 0; i < 5; i++) {
      await vitalsRepository.addWeightReading(
        WeightReading(
          id: 'today-$i',
          patientId: 'patient-1',
          recordedAt: now.subtract(Duration(minutes: i * 10)),
          valueKg: 70.0 + i,
        ),
      );
    }

    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('+ 2 more readings'),
      find.byType(CustomScrollView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(find.text('+ 2 more readings'), findsOneWidget);
    expect(find.text('This Week'), findsAtLeastNWidgets(1));
    expect(find.byType(WeightRecentCard), findsNWidgets(3));
  });

  testWidgets('groups recent readings under week headers', (tester) async {
    final now = DateTime.now();
    final thisWeek = DateTime(now.year, now.month, now.day);
    final lastWeek = thisWeek.subtract(const Duration(days: 7));

    await vitalsRepository.addWeightReading(
      WeightReading(
        id: 'this-week',
        patientId: 'patient-1',
        recordedAt: thisWeek.toUtc(),
        valueKg: 72.0,
      ),
    );
    await vitalsRepository.addWeightReading(
      WeightReading(
        id: 'last-week',
        patientId: 'patient-1',
        recordedAt: lastWeek.toUtc(),
        valueKg: 71.0,
      ),
    );

    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    expect(find.text('This Week'), findsAtLeastNWidgets(1));
    expect(find.text('Last Week'), findsOneWidget);
  });

  testWidgets('Summary/Graph toggle changes views and displays summary table',
      (tester) async {
    await vitalsRepository.addWeightReading(
      WeightReading(
        id: 'weight-1',
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc(),
        valueKg: 72.5,
      ),
    );

    await tester.pumpWidget(buildWeightView(vitalsRepository: vitalsRepository));
    await tester.pumpAndSettle();

    expect(find.text('WT'), findsNothing);

    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();

    expect(find.text('WT'), findsOneWidget);
    expect(find.text('Avg'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('StdDev'), findsOneWidget);
  });
}
