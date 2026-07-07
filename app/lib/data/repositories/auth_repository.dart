import 'package:app/data/local/app_database.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/domain/models/sign_up_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single source of truth for authentication state and actions.
class AuthRepository {
  AuthRepository({
    required AuthService authService,
    required AppDatabase db,
  })  : _authService = authService,
        _db = db;

  final AuthService _authService;
  final AppDatabase _db;

  Stream<AuthState> get onAuthStateChange => _authService.onAuthStateChange;

  Session? get currentSession => _authService.currentSession;

  bool get isSignedIn => currentSession != null;

  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _authService.signIn(email: email, password: password);
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _authService.signUp(
      email: email,
      password: password,
    );

    return SignUpResult(
      status: response.session == null
          ? SignUpStatus.emailConfirmationRequired
          : SignUpStatus.sessionCreated,
    );
  }

  Future<void> signOut() async {
    await _db.wipeAllData();
    await _authService.signOut();
  }
}
