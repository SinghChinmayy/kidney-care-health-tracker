// Basic smoke tests for the Kidney Care app's sample login screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_app/main.dart';

void main() {
  setUpAll(() async {
    // No real network calls happen for these tests: with no stored session,
    // AuthGate renders LoginScreen synchronously and never touches Supabase.
    // Supabase still needs to be initialized once since screens read
    // `Supabase.instance.client` in initState.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://127.0.0.1:54321',
      publishableKey: 'test-publishable-key',
    );
  });

  testWidgets('Login screen shows branding and form fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KidneyCareApp());

    expect(find.text('Kidney Care'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('Login screen validates empty fields on submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KidneyCareApp());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });
}
