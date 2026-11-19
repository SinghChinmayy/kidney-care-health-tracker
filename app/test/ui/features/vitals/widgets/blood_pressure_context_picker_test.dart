import 'package:app/domain/models/blood_pressure_context.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_context_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BloodPressureContext Function()> pumpPicker(
    WidgetTester tester, {
    BloodPressureContext initial = BloodPressureContext.empty,
  }) async {
    var value = initial;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: BloodPressureContextPicker(
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );
    return () => value;
  }

  testWidgets('collapsed by default and expands to edit arm/posture',
      (tester) async {
    final current = await pumpPicker(tester);
    expect(find.text('Arm'), findsNothing);

    await tester.tap(find.text('Measurement details'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Right arm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standing'));
    await tester.pumpAndSettle();

    expect(current().arm, bpArmRight);
    expect(current().posture, bpPostureStanding);
    expect(find.text('Right arm · Standing'), findsOneWidget);
  });

  testWidgets('timing only shows on dialysis days and clears when unset',
      (tester) async {
    final current = await pumpPicker(
      tester,
      initial: const BloodPressureContext(
        isDialysisDay: true,
        dialysisPhase: bpDialysisPhasePost,
      ),
    );

    // Expanded because context is present.
    expect(find.text('Timing'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    expect(find.text('Timing'), findsNothing);
    expect(current().isDialysisDay, isFalse);
    expect(current().dialysisPhase, isNull);
  });
}
