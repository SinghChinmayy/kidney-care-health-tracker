import 'package:app/data/services/auth_service.dart';
import 'package:app/domain/models/sign_up_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single source of truth for authentication state and actions.
class AuthRepository {
  AuthRepository({required AuthService authService})
      : _authService = authService;

  final AuthService _authService;

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

  Future<void> signOut() {
    return _authService.signOut();
  }
}
