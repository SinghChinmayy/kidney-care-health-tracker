import 'package:app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _InMemoryAsyncStorage extends GotrueAsyncStorage {
  final _store = <String, String>{};

  @override
  Future<void> removeItem({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<String?> getItem({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _store[key] = value;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4YW1wbGUiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0NTA2MDAwMCwiZXhwIjoxOTYwNjM2MDAwfQ.example',
      authOptions: FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _InMemoryAsyncStorage(),
      ),
    );
  });

  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const KidneyCareApp());

    expect(find.text('Kidney Care'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
