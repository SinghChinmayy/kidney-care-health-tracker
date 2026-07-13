import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/views/blood_glucose_view.dart';
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

    expect(find.text('Blood glucose'), findsOneWidget);
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

    await tester.ensureVisible(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fasting'), findsOneWidget);

    await tester.tap(find.text('Today'));
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

    expect(find.text('Glucose deleted'), findsOneWidget);

    final readings = await vitalsRepository.getBloodGlucoseReadings();
    expect(readings, isEmpty);
  });

  testWidgets('period chips switch labels', (tester) async {
    await tester.pumpWidget(
      buildBloodGlucoseView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    expect(find.text('This Month'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('All Time'), findsOneWidget);
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

    await tester.ensureVisible(find.text('Yesterday'));
    await tester.pumpAndSettle();
    expect(find.text('118'), findsWidgets);
    expect(find.text('Yesterday'), findsOneWidget);
  });
}
