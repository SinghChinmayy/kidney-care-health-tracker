import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/data/services/google_id_token_source.dart';
import 'package:app/ui/features/auth/view_models/login_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ScriptedAuthService extends AuthService {
  _ScriptedAuthService(this.onGoogle)
      : super(
          client: SupabaseClient('http://localhost:54321', 'anon-key'),
          googleIdTokenSource: _NoGoogle(),
        );

  final Future<bool> Function() onGoogle;

  @override
  Future<bool> signInWithGoogle() => onGoogle();
}

class _NoGoogle implements GoogleIdTokenSource {
  @override
  Future<String?> obtainIdToken() async => null;

  @override
  Future<void> signOut() async {}
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  LoginViewModel build(Future<bool> Function() onGoogle) {
    return LoginViewModel(
      authRepository: AuthRepository(
        authService: _ScriptedAuthService(onGoogle),
        db: db,
      ),
    );
  }

  test('google success clears loading and error', () async {
    final vm = build(() async => true);
    expect(await vm.signInWithGoogle(), isTrue);
    expect(vm.isLoading, isFalse);
    expect(vm.errorMessage, isNull);
  });

  test('cancelled google picker is not an error', () async {
    final vm = build(() async => false);
    expect(await vm.signInWithGoogle(), isFalse);
    expect(vm.errorMessage, isNull);
  });

  test('unconfigured build shows a setup message', () async {
    final vm = build(() async => throw const GoogleSignInNotConfiguredException());
    expect(await vm.signInWithGoogle(), isFalse);
    expect(vm.errorMessage, 'Google sign-in is not set up for this build.');
  });

  test('supabase auth errors surface their message', () async {
    final vm = build(() async => throw const AuthException('Provider is disabled'));
    expect(await vm.signInWithGoogle(), isFalse);
    expect(vm.errorMessage, 'Provider is disabled');
  });
}
