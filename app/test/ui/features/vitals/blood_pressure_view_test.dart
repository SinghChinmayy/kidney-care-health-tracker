import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:app/ui/features/vitals/views/blood_pressure_view.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_recent_card.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

Future<void> seedBloodPressurePatient(AppDatabase db) async {
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

Widget buildBloodPressureView({
  required VitalsRepository vitalsRepository,
}) {
  return ChangeNotifierProvider(
    create: (_) => BloodPressureViewModel(vitalsRepository: vitalsRepository),
    child: MaterialApp(
      theme: AppTheme.light,
      home: const BloodPressureView(),
    ),
  );
}

void main() {
  late AppDatabase db;
  late VitalsRepository vitalsRepository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedBloodPressurePatient(db);
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

  testWidgets('renders activity-style blood pressure page', (tester) async {
    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blood Pressure'), findsOneWidget);
    expect(find.text('7D'), findsOneWidget);
    expect(find.text('30D'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.textContaining('Last 7 Days'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('TRACK'), findsNothing);
    expect(find.text('HISTORY'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Log'), findsOneWidget);
  });

  testWidgets('scaffold uses warm cream background color', (tester) async {
    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppTheme.bpBackground);
  });

  testWidgets('add opens log sheet and save persists reading', (tester) async {
    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Log blood pressure'), findsWidgets);
    expect(find.text('LOG TYPE'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Blood pressure saved'), findsOneWidget);

    final readings = await vitalsRepository.getBloodPressureReadings();
    expect(readings, hasLength(1));
    expect(readings.first.systolic, 120);
    expect(readings.first.diastolic, 80);
  });

  testWidgets('Recent shows readings and opens edit sheet', (tester) async {
    const readingId = 'bp-edit-1';
    await vitalsRepository.addBloodPressureReading(
      BloodPressureReading(
        id: readingId,
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc(),
        systolic: 120,
        diastolic: 80,
      ),
    );

    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(BloodPressureRecentCard),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.byType(BloodPressureRecentCard).first);
    await tester.pumpAndSettle();
    expect(find.text('120/80'), findsWidgets);

    await tester.tap(find.byType(BloodPressureRecentCard).first);
    await tester.pumpAndSettle();

    expect(find.text('Edit blood pressure'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Blood pressure updated'), findsOneWidget);

    final readings = await vitalsRepository.getBloodPressureReadings();
    expect(readings, hasLength(1));
    expect(readings.first.id, readingId);
    // Last stepper add icon bumps diastolic (bottom field).
    expect(readings.first.diastolic, 81);
  });

  testWidgets('Delete removes reading from edit sheet', (tester) async {
    const readingId = 'bp-delete-1';
    await vitalsRepository.addBloodPressureReading(
      BloodPressureReading(
        id: readingId,
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc(),
        systolic: 120,
        diastolic: 80,
      ),
    );

    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(BloodPressureRecentCard),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.byType(BloodPressureRecentCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BloodPressureRecentCard).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete reading'));
    await tester.tap(find.text('Delete reading'));
    await tester.pumpAndSettle();

    expect(find.text('Delete reading?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Blood pressure deleted'), findsOneWidget);

    final readings = await vitalsRepository.getBloodPressureReadings();
    expect(readings, isEmpty);
  });

  testWidgets('period chips switch labels', (tester) async {
    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This Month'), findsOneWidget);

    await tester.tap(find.text('30D'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Last 30 Days'), findsOneWidget);
  });

  testWidgets('seeded history appears in Recent without tabs', (tester) async {
    await vitalsRepository.addBloodPressureReading(
      BloodPressureReading(
        id: const Uuid().v4(),
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        systolic: 118,
        diastolic: 76,
      ),
    );

    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(BloodPressureRecentCard),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('118/76'), findsWidgets);
    expect(find.byType(BloodPressureRecentCard), findsOneWidget);
  });

  testWidgets('shows max 3 readings per day and a N-more row', (tester) async {
    final now = DateTime.now().toUtc();
    for (var i = 0; i < 5; i++) {
      await vitalsRepository.addBloodPressureReading(
        BloodPressureReading(
          id: 'today-$i',
          patientId: 'patient-1',
          recordedAt: now.subtract(Duration(minutes: i * 10)),
          systolic: 120 + i,
          diastolic: 80,
        ),
      );
    }

    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    // Scroll to Recent section
    await tester.dragUntilVisible(
      find.text('+ 2 more readings'),
      find.byType(CustomScrollView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(find.text('+ 2 more readings'), findsOneWidget);
    expect(find.text('Today'), findsNWidgets(3));
  });

  testWidgets('tapping N-more row expands all readings for that day',
      (tester) async {
    final now = DateTime.now().toUtc();
    for (var i = 0; i < 4; i++) {
      await vitalsRepository.addBloodPressureReading(
        BloodPressureReading(
          id: 'expand-$i',
          patientId: 'patient-1',
          recordedAt: now.subtract(Duration(minutes: i * 5)),
          systolic: 115 + i,
          diastolic: 75,
        ),
      );
    }

    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    // Scroll to the "N more" row
    await tester.dragUntilVisible(
      find.text('+ 1 more reading'),
      find.byType(CustomScrollView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(find.text('+ 1 more reading'), findsOneWidget);
    expect(find.text('Today'), findsNWidgets(3));

    // Tap to expand
    await tester.tap(find.text('+ 1 more reading'));
    await tester.pumpAndSettle();

    expect(find.text('+ 1 more reading'), findsNothing);
    expect(find.text('Today'), findsNWidgets(4));
  });

  testWidgets('3 or fewer readings per day shows no N-more row',
      (tester) async {
    final now = DateTime.now().toUtc();
    for (var i = 0; i < 3; i++) {
      await vitalsRepository.addBloodPressureReading(
        BloodPressureReading(
          id: 'exact-$i',
          patientId: 'patient-1',
          recordedAt: now.subtract(Duration(minutes: i * 15)),
          systolic: 120,
          diastolic: 80,
        ),
      );
    }

    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('more reading'), findsNothing);
    expect(find.byType(BloodPressureRecentCard), findsNWidgets(3));
  });

  testWidgets('Summary/Graph toggle changes views and displays summary table',
      (tester) async {
    await vitalsRepository.addBloodPressureReading(
      BloodPressureReading(
        id: 'bp-1',
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc(),
        systolic: 120,
        diastolic: 80,
      ),
    );

    await tester.pumpWidget(
      buildBloodPressureView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    // Initially Graph view
    expect(find.text('Summary mmHg'), findsNothing);

    // Tap 'Summary' on the Summary/Graph top toggle
    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();

    // Now Summary table is displayed
    expect(find.text('SYS'), findsOneWidget);
    expect(find.text('DIA'), findsOneWidget);
    expect(find.text('Avg'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('StdDev'), findsOneWidget);
  });
}
