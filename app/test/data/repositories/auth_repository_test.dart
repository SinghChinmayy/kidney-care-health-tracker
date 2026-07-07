import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/domain/models/patient.dart';
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
  late AppDatabase db;
  late AuthRepository authRepository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
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

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    authRepository = AuthRepository(
      authService: AuthService(),
      db: db,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('signOut wipes all local health data', () async {
    final now = DateTime.utc(2026, 7, 8, 10);
    await db.patientsDao.insertPatient(
      Patient(
        id: 'patient-1',
        authUserId: 'auth-1',
        createdAt: now,
        updatedAt: now,
      ),
      isDirty: false,
    );

    expect(await db.hasLocalDataForAuthUser('auth-1'), isTrue);

    await authRepository.signOut();

    expect(await db.hasLocalDataForAuthUser('auth-1'), isFalse);
    expect(await db.patientsDao.hasAnyData(), isFalse);
  });

  test('hasLocalDataForAuthUser is false for unknown auth user', () async {
    expect(await db.hasLocalDataForAuthUser('missing'), isFalse);
  });
}
