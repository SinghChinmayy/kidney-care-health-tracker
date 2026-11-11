import 'package:app/app.dart';
import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/database_holder.dart';
import 'package:app/data/repositories/active_patient_notifier.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/sharing_repository.dart';
import 'package:app/data/sync/sync_coordinator.dart';
import 'package:app/ui/features/auth/views/login_view.dart';
import 'package:app/ui/features/patients/view_models/patients_view_model.dart';
import 'package:provider/provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _InMemoryAsyncStorage extends GotrueAsyncStorage {
  final _store = <String, String>{};

  @override
  Future<void> removeItem({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<String?> getItem({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _store[key] = value;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    appDatabase = AppDatabase.forTesting(NativeDatabase.memory());
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4YW1wbGUiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0NTA2MDAwMCwiZXhwIjoxOTYwNjM2MDAwfQ.example',
      authOptions: FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _InMemoryAsyncStorage(),
      ),
    );
  });

  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const KidneyCareApp());

    expect(find.text('Kidney Care'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('provider graph resolves and survives a patient switch',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KidneyCareApp());
    final context = tester.element(find.byType(LoginView));

    final coordinator = context.read<SyncCoordinator>();
    final patients = context.read<PatientRepository>();
    expect(context.read<SharingRepository>(), isNotNull);
    expect(context.read<PatientsViewModel>(), isNotNull);

    context.read<ActivePatientNotifier>().markChanged();
    await tester.pump();

    expect(identical(context.read<SyncCoordinator>(), coordinator), isTrue);
    expect(identical(context.read<PatientRepository>(), patients), isTrue);
  });
}
