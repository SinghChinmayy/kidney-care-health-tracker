/// Supabase connection settings passed at build/run time via `--dart-define`.
///
/// Local development:
/// ```bash
/// flutter run --dart-define-from-file=dart_defines/dev.json
/// ```
///
/// Copy `dart_defines/dev.example.json` to `dart_defines/dev.json` and fill in
/// your project values. The real `dev.json` is gitignored.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');

  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static String? get validationError {
    if (url.isEmpty || publishableKey.isEmpty) {
      return 'Copy dart_defines/dev.example.json to dart_defines/dev.json, '
          'then run:\n'
          'flutter run --dart-define-from-file=dart_defines/dev.json';
    }
    return null;
  }

  static void validate() {
    final error = validationError;
    if (error != null) {
      throw StateError(error);
    }
  }
}
