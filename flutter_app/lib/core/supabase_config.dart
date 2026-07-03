/// Supabase connection settings.
///
/// Defaults point at the local Supabase dev stack (`supabase start`, see
/// `supabase/config.toml`). The publishable key below is the fixed,
/// publicly documented demo key the Supabase CLI issues for every local
/// project — it is not a secret. To point the app at a different (e.g.
/// hosted) project, override both values at build/run time:
///
/// ```sh
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
/// ```
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );
}
