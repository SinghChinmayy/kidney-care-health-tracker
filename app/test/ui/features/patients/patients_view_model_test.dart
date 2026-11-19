import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/active_patient_notifier.dart';
import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/data/services/google_id_token_source.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/ui/features/patients/view_models/patients_view_model.dart';
import 'package:app/ui/features/patients/widgets/active_patient_bar.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoGoogle implements GoogleIdTokenSource {
  @override
  Future<String?> obtainIdToken() async => null;
  @override
  Future<void> signOut() async {}
}

class _SignedInAuthService extends AuthService {
  _SignedInAuthService()
      : super(
          client: SupabaseClient('http://localhost:54321', 'anon-key'),
          googleIdTokenSource: _NoGoogle(),
        );

  @override
  Session? get currentSession => Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: const User(
          id: 'auth-me',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-11-12T00:00:00Z',
        ),
      );
}

void main() {
  late AppDatabase db;
  late ActivePatientNotifier notifier;
  late PatientsViewModel viewModel;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notifier = ActivePatientNotifier();
    final now = DateTime.utc(2026, 11, 1);
    await db.patientsDao.insertPatient(
      Patient(id: 'p-self', authUserId: 'auth-me', firstName: 'Me',
          createdAt: now, updatedAt: now),
      isDirty: false,
    );
    await db.patientsDao.insertPatient(
      Patient(id: 'p-mum', firstName: 'Mum', createdAt: now, updatedAt: now),
      isDirty: false,
    );
    await db.patientAccessDao.upsertMembership(
      patientId: 'p-mum',
      role: 'caregiver',
      updatedAt: now,
    );
    viewModel = PatientsViewModel(
      authRepository: AuthRepository(
        authService: _SignedInAuthService(),
        db: db,
      ),
      patientRepository: PatientRepository(
        db: db,
        activePatientNotifier: notifier,
      ),
      activePatientNotifier: notifier,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await db.close();
  });

  testWidgets('switching shows the viewing bar and notifies screens',
      (tester) async {
    await tester.runAsync(viewModel.refresh);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: viewModel,
          child: const Scaffold(body: ActivePatientBar()),
        ),
      ),
    );
    expect(viewModel.activePatient!.isSelf, isTrue);
    expect(find.byKey(const ValueKey('active-patient-bar')), findsNothing);

    await tester.runAsync(() async {
      await viewModel.switchTo('p-mum');
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(notifier.revision, 1);
    expect(viewModel.isViewingOther, isTrue);
    expect(find.text('Viewing Mum · Caregiver'), findsOneWidget);
  });
}
