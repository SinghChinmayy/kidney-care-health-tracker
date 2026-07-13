import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/views/blood_glucose_view.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_recent_card.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

Future<void> seedGlucosePatient(AppDatabase db) async {
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

Widget buildBloodGlucoseView({
  required VitalsRepository vitalsRepository,
}) {
  return ChangeNotifierProvider(
    create: (_) => BloodGlucoseViewModel(vitalsRepository: vitalsRepository),
    child: MaterialApp(
      theme: AppTheme.light,
      home: const BloodGlucoseView(),
    ),
  );
}

void main() {
  late AppDatabase db;
  late VitalsRepository vitalsRepository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedGlucosePatient(db);
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

  testWidgets('renders activity-style glucose page', (tester) async {
    await tester.pumpWidget(
      buildBloodGlucoseView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blood Glucose'), findsOneWidget);
    expect(find.text('7D'), findsOneWidget);
    expect(find.text('30D'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.textContaining('Last 7 Days'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Graph'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Log'), findsOneWidget);
  });

  testWidgets('scaffold uses warm cream background color', (tester) async {
    await tester.pumpWidget(
      buildBloodGlucoseView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppTheme.bpBackground);
  });

  testWidgets('add opens log sheet and save persists reading', (tester) async {
    await tester.pumpWidget(
      buildBloodGlucoseView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Log blood glucose'), findsWidgets);
    expect(find.text('Context'), findsOneWidget);

    final fields = find.byType(TextField);
    expect(fields, findsWidgets);
    await tester.enterText(fields.first, '130');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Blood glucose saved'), findsOneWidget);

    final readings = await vitalsRepository.getBloodGlucoseReadings();
    expect(readings, hasLength(1));
    expect(readings.first.valueMgDl, 130.0);
  });

  testWidgets('Recent shows readings and opens edit sheet', (tester) async {
    const readingId = 'glucose-edit-1';
    await vitalsRepository.addBloodGlucoseReading(
      BloodGlucoseReading(
        id: readingId,
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc(),
        valueMgDl: 120,
        context: 'fasting',
      ),
    );

    await tester.pumpWidget(
      buildBloodGlucoseView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(BloodGlucoseRecentCard),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.byType(BloodGlucoseRecentCard).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Fasting'), findsWidgets);

    await tester.tap(find.byType(BloodGlucoseRecentCard).first);
    await tester.pumpAndSettle();

    expect(find.text('Edit blood glucose'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Glucose updated'), findsOneWidget);

    final readings = await vitalsRepository.getBloodGlucoseReadings();
    expect(readings, hasLength(1));
    expect(readings.first.id, readingId);
    expect(readings.first.valueMgDl, 121.0);
  });

  testWidgets('Delete removes reading from edit sheet', (tester) async {
    const readingId = 'glucose-delete-1';
    await vitalsRepository.addBloodGlucoseReading(
      BloodGlucoseReading(
        id: readingId,
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc(),
        valueMgDl: 120,
      ),
    );

    await tester.pumpWidget(
      buildBloodGlucoseView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(BloodGlucoseRecentCard),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.byType(BloodGlucoseRecentCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BloodGlucoseRecentCard).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete reading'));
    await tester.tap(find.text('Delete reading'));
    await tester.pumpAndSettle();

    expect(find.text('Delete reading?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Glucose deleted'), findsOneWidget);

    final readings = await vitalsRepository.getBloodGlucoseReadings();
    expect(readings, isEmpty);
  });

  testWidgets('period chips switch labels', (tester) async {
    await tester.pumpWidget(
      buildBloodGlucoseView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This Month'), findsWidgets);

    await tester.tap(find.text('30D'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Last 30 Days'), findsOneWidget);
  });

  testWidgets('seeded history appears in Recent without tabs', (tester) async {
    await vitalsRepository.addBloodGlucoseReading(
      BloodGlucoseReading(
        id: const Uuid().v4(),
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        valueMgDl: 118,
      ),
    );

    await tester.pumpWidget(
      buildBloodGlucoseView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(BloodGlucoseRecentCard),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('118'), findsWidgets);
    expect(find.byType(BloodGlucoseRecentCard), findsOneWidget);
  });

  testWidgets('shows max 3 readings per week and a N-more row', (tester) async {
    final now = DateTime.now().toUtc();
    for (var i = 0; i < 5; i++) {
      await vitalsRepository.addBloodGlucoseReading(
        BloodGlucoseReading(
          id: 'today-$i',
          patientId: 'patient-1',
          recordedAt: now.subtract(Duration(minutes: i * 15)),
          valueMgDl: 120.0 + i,
        ),
      );
    }

    await tester.pumpWidget(
      buildBloodGlucoseView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('more reading'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.byType(BloodGlucoseRecentCard), findsNWidgets(3));
  });

  testWidgets('Summary/Graph toggle changes views and displays summary table',
      (tester) async {
    await vitalsRepository.addBloodGlucoseReading(
      BloodGlucoseReading(
        id: 'glucose-1',
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc(),
        valueMgDl: 120,
      ),
    );

    await tester.pumpWidget(
      buildBloodGlucoseView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('GLU'), findsNothing);

    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();

    expect(find.text('GLU'), findsOneWidget);
    expect(find.text('Avg'), findsOneWidget);
    expect(find.text('StdDev'), findsOneWidget);
  });
}
