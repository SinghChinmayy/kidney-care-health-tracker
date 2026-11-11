import 'dart:developer' as developer;

import 'package:app/data/services/google_id_token_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around [SupabaseClient.auth].
class AuthService {
  AuthService({
    SupabaseClient? client,
    GoogleIdTokenSource? googleIdTokenSource,
  })  : _client = client ?? Supabase.instance.client,
        _google = googleIdTokenSource ?? NativeGoogleIdTokenSource();

  final SupabaseClient _client;
  final GoogleIdTokenSource _google;

  GoTrueClient get _auth => _client.auth;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Session? get currentSession => _auth.currentSession;

  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Native Google sign-in exchanged for a Supabase session.
  ///
  /// Returns `false` when the user dismissed the Google account picker.
  Future<bool> signInWithGoogle() async {
    final idToken = await _google.obtainIdToken();
    if (idToken == null) {
      return false;
    }
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
    return true;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    try {
      // Clear the cached Google account so the picker shows next time.
      await _google.signOut();
    } catch (error) {
      developer.log('Google sign-out failed: $error', name: 'AuthService');
    }
    await _auth.signOut();
  }
}
