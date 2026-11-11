# Google sign-in (Android)

The login screen's **Continue with Google** button uses native Google sign-in
(`google_sign_in` 7.x → Android Credential Manager) and exchanges the returned
Google ID token for a Supabase session with `auth.signInWithIdToken`. No
browser redirect is involved. Only Android is wired up (the repo has no iOS
runner yet).

```text
Continue with Google
  -> GoogleSignIn.instance.initialize(serverClientId: GOOGLE_WEB_CLIENT_ID)  (once)
  -> GoogleSignIn.instance.authenticate()        -> account picker
  -> account.authentication.idToken              (aud = Web client id)
  -> supabase.auth.signInWithIdToken(provider: google, idToken)
  -> Supabase verifies the token, creates auth.users on first sign-in
  -> signup trigger creates the self patient row
  -> AuthGate sees the session -> InitialSyncGate -> app
```

Code: `app/lib/core/google_auth_config.dart`,
`app/lib/data/services/google_id_token_source.dart`,
`app/lib/data/services/auth_service.dart` (`signInWithGoogle`),
`app/lib/ui/features/auth/view_models/login_view_model.dart`.

## 1. Google Cloud Console

1. Create (or pick) a project and configure the OAuth consent screen
   (scopes: `openid`, `email`, `profile`).
2. **Credentials → Create OAuth client ID → Web application.** Note the
   client ID and client secret. Add Supabase's callback as an authorised
   redirect URI: `https://<project-ref>.supabase.co/auth/v1/callback`
   (not used by the native flow, but required by the dashboard provider form).
3. **Credentials → Create OAuth client ID → Android.**
   - Package name: the `applicationId` in `app/android/app/build.gradle.kts`
     (currently `com.example.app`).
   - SHA-1 of the signing key. Debug key:

     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore \
       -alias androiddebugkey -storepass android -keypass android
     ```

     Add a second Android client (or fingerprint) for the release key.

   The Android client is never referenced from code; Google matches it by
   package name + signature. If it is missing, `authenticate()` fails with a
   configuration error.

## 2. App build (dart-defines)

`app/dart_defines/dev.example.json` lists the keys with empty placeholders.
Put the **Web** client ID (not the Android one) in your gitignored
`dart_defines/dev.json`:

```json
{
  "SUPABASE_URL": "...",
  "SUPABASE_PUBLISHABLE_KEY": "...",
  "GOOGLE_WEB_CLIENT_ID": "1234-abc.apps.googleusercontent.com"
}
```

Run with `flutter run --dart-define-from-file=dart_defines/dev.json`. With an
empty `GOOGLE_WEB_CLIENT_ID` the button shows "Google sign-in is not set up
for this build." instead of crashing.

## 3. Supabase

**Hosted project:** Dashboard → Authentication → Sign In / Providers →
Google → enable, paste the Web client ID and secret. If you later add iOS,
put both client IDs in *Client IDs* comma-separated.

**Local stack:** `supabase/config.toml` has an `[auth.external.google]`
block that only references environment variables. Provide them in
`supabase/.env` (gitignored) or your shell, then restart the stack:

```bash
# supabase/.env
SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID=1234-abc.apps.googleusercontent.com
SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET=...
```

```bash
supabase stop && supabase start
```

If the variables are unset the CLI prints a warning and the provider stays
enabled with an empty client ID (any Google token is rejected) — email/password
auth is unaffected. `skip_nonce_check = false` is fine: the native Android flow
does not put a nonce in the token.

## Not ported from v1

v1's `auth_service.dart` posted debug payloads (including a masked client ID)
to a local HTTP ingest endpoint. That instrumentation was dropped. v1 read the
client ID from `flutter_dotenv`; v2 uses dart-defines like the Supabase keys.
