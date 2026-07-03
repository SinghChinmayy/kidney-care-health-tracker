import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around `Supabase.instance.client.auth`.
///
/// Session persistence across app restarts (the "local auth" side of
/// things) is handled automatically by `supabase_flutter`'s built-in local
/// storage — no separate local session store is needed. This class exists
/// so screens don't talk to the Supabase SDK directly, keeping the auth
/// method (email/password today) swappable later.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  /// Emits on every auth state change (sign-in, sign-out, token refresh,
  /// initial session restore on app start).
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
