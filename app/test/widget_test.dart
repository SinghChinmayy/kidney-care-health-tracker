import 'package:app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const KidneyCareApp());

    expect(find.text('Kidney Care'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
