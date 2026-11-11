import 'package:app/domain/models/blood_pressure_context.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalized drops dialysis phase unless it is a dialysis day', () {
    const context = BloodPressureContext(
      isDialysisDay: false,
      dialysisPhase: bpDialysisPhasePre,
    );
    expect(context.normalized().dialysisPhase, isNull);

    const onDialysisDay = BloodPressureContext(
      isDialysisDay: true,
      dialysisPhase: bpDialysisPhasePost,
    );
    expect(onDialysisDay.normalized().dialysisPhase, bpDialysisPhasePost);
  });

  test('normalized drops values outside the server vocabulary', () {
    const context = BloodPressureContext(arm: 'both', posture: 'lying_down');
    final normalized = context.normalized();
    expect(normalized.arm, isNull);
    expect(normalized.posture, isNull);
    expect(normalized.isEmpty, isTrue);
  });

  test('context labels are human readable and ordered', () {
    expect(
      formatBloodPressureContextLabels(
        const BloodPressureContext(
          arm: bpArmLeft,
          posture: bpPostureLying,
          isDialysisDay: true,
          dialysisPhase: bpDialysisPhasePre,
        ),
      ),
      ['Left arm', 'Lying down', 'Before dialysis'],
    );
    expect(
      formatBloodPressureContextSummary(
        const BloodPressureContext(isDialysisDay: true),
      ),
      'Dialysis day',
    );
    expect(
      formatBloodPressureContextSummary(BloodPressureContext.empty),
      isNull,
    );
  });
}
