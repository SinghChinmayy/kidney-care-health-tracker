/// Google sign-in client configuration passed at build/run time via
/// `--dart-define` (see `dart_defines/dev.example.json` and
/// `docs/google-sign-in.md`).
///
/// Only the **Web** OAuth client id is needed in the app: on Android,
/// `google_sign_in` uses it as `serverClientId` so the returned ID token's
/// audience is the web client that Supabase verifies. The Android OAuth
/// client (package name + SHA-1) is registered in Google Cloud but never
/// referenced from code.
abstract final class GoogleAuthConfig {
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static bool get isConfigured => webClientId.isNotEmpty;
}
