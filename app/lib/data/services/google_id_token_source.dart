import 'package:app/core/google_auth_config.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thrown when Google sign-in cannot run in this build (no client id).
class GoogleSignInNotConfiguredException implements Exception {
  const GoogleSignInNotConfiguredException();

  @override
  String toString() =>
      'Google sign-in is not configured (GOOGLE_WEB_CLIENT_ID is empty).';
}

/// Obtains a Google ID token for Supabase `signInWithIdToken`.
abstract interface class GoogleIdTokenSource {
  /// Returns an ID token, or `null` if the user dismissed the picker.
  Future<String?> obtainIdToken();

  Future<void> signOut();
}

/// Native account picker via `google_sign_in` (Credential Manager on Android).
class NativeGoogleIdTokenSource implements GoogleIdTokenSource {
  NativeGoogleIdTokenSource({
    GoogleSignIn? googleSignIn,
    String webClientId = GoogleAuthConfig.webClientId,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _serverClientId = webClientId;

  final GoogleSignIn _googleSignIn;
  final String _serverClientId;
  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    // GoogleSignIn.initialize must run exactly once per app process.
    return _initialization ??=
        _googleSignIn.initialize(serverClientId: _serverClientId);
  }

  @override
  Future<String?> obtainIdToken() async {
    if (_serverClientId.isEmpty) {
      throw const GoogleSignInNotConfiguredException();
    }
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google returned no ID token; check GOOGLE_WEB_CLIENT_ID is the Web '
        'OAuth client id.',
      );
    }
    return idToken;
  }

  @override
  Future<void> signOut() async {
    if (_initialization == null) {
      return;
    }
    await _googleSignIn.signOut();
  }
}
