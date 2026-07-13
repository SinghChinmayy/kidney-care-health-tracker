import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/fluid_intake_view_model.dart';
import 'package:app/ui/features/vitals/views/fluid_intake_view.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

Future<void> seedFluidPatient(AppDatabase db) async {
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

Widget buildFluidIntakeView({
  required VitalsRepository vitalsRepository,
}) {
  return ChangeNotifierProvider(
    create: (_) => FluidIntakeViewModel(vitalsRepository: vitalsRepository),
    child: MaterialApp(
      theme: AppTheme.light,
      home: const FluidIntakeView(),
    ),
  );
}

void main() {
  late AppDatabase db;
  late VitalsRepository vitalsRepository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedFluidPatient(db);
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

  testWidgets('renders vitals-style water intake page', (tester) async {
    await tester.pumpWidget(
      buildFluidIntakeView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Water intake'), findsWidgets);
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

  testWidgets('add opens log sheet and save persists log', (tester) async {
    await tester.pumpWidget(
      buildFluidIntakeView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('Water'), findsWidgets);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Water intake saved'), findsOneWidget);

    final logs = await vitalsRepository.getFluidIntakeLogs();
    expect(logs, hasLength(1));
    expect(logs.first.fluidMl, 250.0);
  });

  testWidgets('Recent shows logs and opens edit sheet', (tester) async {
    const logId = 'fluid-edit-1';
    await vitalsRepository.addFluidIntakeLog(
      FluidIntakeLog(
        id: logId,
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc(),
        fluidMl: 250,
      ),
    );

    await tester.pumpWidget(
      buildFluidIntakeView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Today'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Edit water intake'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Water intake updated'), findsOneWidget);

    final logs = await vitalsRepository.getFluidIntakeLogs();
    expect(logs, hasLength(1));
    expect(logs.first.id, logId);
  });

  testWidgets('Delete removes log from edit sheet', (tester) async {
    const logId = 'fluid-delete-1';
    await vitalsRepository.addFluidIntakeLog(
      FluidIntakeLog(
        id: logId,
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc(),
        fluidMl: 250,
      ),
    );

    await tester.pumpWidget(
      buildFluidIntakeView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete log'));
    await tester.tap(find.text('Delete log'));
    await tester.pumpAndSettle();

    expect(find.text('Delete log?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Water intake deleted'), findsOneWidget);

    final logs = await vitalsRepository.getFluidIntakeLogs();
    expect(logs, isEmpty);
  });

  testWidgets('period chips switch labels', (tester) async {
    await tester.pumpWidget(
      buildFluidIntakeView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('This Month'), findsOneWidget);

    await tester.tap(find.text('30D'));
    await tester.pumpAndSettle();
    expect(find.text('Last 30 Days'), findsOneWidget);
  });

  testWidgets('seeded history appears in Recent without tabs', (tester) async {
    await vitalsRepository.addFluidIntakeLog(
      FluidIntakeLog(
        id: const Uuid().v4(),
        patientId: 'patient-1',
        recordedAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        fluidMl: 200,
      ),
    );

    await tester.pumpWidget(
      buildFluidIntakeView(vitalsRepository: vitalsRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('200'), findsWidgets);
    expect(find.text('TRACK'), findsNothing);
  });
}
