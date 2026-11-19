import 'dart:convert';

import 'package:app/data/services/auth_service.dart';
import 'package:app/data/services/google_id_token_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeGoogle implements GoogleIdTokenSource {
  _FakeGoogle(this.token);

  final String? token;
  int signOutCalls = 0;

  @override
  Future<String?> obtainIdToken() async => token;

  @override
  Future<void> signOut() async => signOutCalls++;
}

Map<String, dynamic> _sessionJson() {
  final now = DateTime.now().toUtc().toIso8601String();
  return {
    'access_token': 'header.${base64Url.encode(utf8.encode(jsonEncode({
          'sub': 'user-1',
          'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        })))}.sig',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh',
    'user': {
      'id': 'user-1',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'g@example.test',
      'app_metadata': {'provider': 'google'},
      'user_metadata': <String, dynamic>{},
      'created_at': now,
    },
  };
}

void main() {
  late List<http.Request> requests;

  SupabaseClient clientWith(MockClient http) {
    return SupabaseClient(
      'http://localhost:54321',
      'anon-key',
      httpClient: http,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  setUp(() => requests = []);

  test('exchanges the Google ID token via signInWithIdToken', () async {
    final mock = MockClient((request) async {
      requests.add(request);
      return http.Response(jsonEncode(_sessionJson()), 200);
    });
    final service = AuthService(
      client: clientWith(mock),
      googleIdTokenSource: _FakeGoogle('google-id-token'),
    );

    final signedIn = await service.signInWithGoogle();

    expect(signedIn, isTrue);
    final request = requests.single;
    expect(request.url.path, '/auth/v1/token');
    expect(request.url.queryParameters['grant_type'], 'id_token');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['provider'], 'google');
    expect(body['id_token'], 'google-id-token');
    expect(service.currentSession?.user.id, 'user-1');
  });

  test('cancelled picker returns false without calling Supabase', () async {
    final mock = MockClient((request) async {
      requests.add(request);
      return http.Response('{}', 500);
    });
    final service = AuthService(
      client: clientWith(mock),
      googleIdTokenSource: _FakeGoogle(null),
    );

    expect(await service.signInWithGoogle(), isFalse);
    expect(requests, isEmpty);
  });

  test('signOut also clears the Google account', () async {
    final google = _FakeGoogle('t');
    final mock = MockClient((request) async => http.Response('{}', 204));
    final service = AuthService(
      client: clientWith(mock),
      googleIdTokenSource: google,
    );

    await service.signOut();

    expect(google.signOutCalls, 1);
  });

  test('native source refuses to run without a web client id', () async {
    final source = NativeGoogleIdTokenSource(webClientId: '');
    expect(
      source.obtainIdToken(),
      throwsA(isA<GoogleSignInNotConfiguredException>()),
    );
  });
}
