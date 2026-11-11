/// Optional measurement context for a blood pressure reading.
///
/// Values match the `blood_pressure_readings` CHECK constraints
/// (planning/db/v0/s2/s2.1). `null` everywhere means "not recorded".
library;

const bpArmLeft = 'left';
const bpArmRight = 'right';
const bpArmOptions = [bpArmLeft, bpArmRight];

const bpPostureSitting = 'sitting';
const bpPostureStanding = 'standing';
const bpPostureLying = 'lying';
const bpPostureOptions = [bpPostureSitting, bpPostureStanding, bpPostureLying];

const bpDialysisPhasePre = 'pre_dialysis';
const bpDialysisPhasePost = 'post_dialysis';
const bpDialysisPhaseOptions = [bpDialysisPhasePre, bpDialysisPhasePost];

class BloodPressureContext {
  const BloodPressureContext({
    this.arm,
    this.posture,
    this.isDialysisDay,
    this.dialysisPhase,
  });

  static const empty = BloodPressureContext();

  final String? arm;
  final String? posture;
  final bool? isDialysisDay;

  /// Only meaningful when [isDialysisDay] is true; [normalized] drops it
  /// otherwise so the server CHECK constraint can never be violated.
  final String? dialysisPhase;

  bool get isEmpty =>
      arm == null &&
      posture == null &&
      isDialysisDay == null &&
      dialysisPhase == null;

  BloodPressureContext normalized() {
    return BloodPressureContext(
      arm: bpArmOptions.contains(arm) ? arm : null,
      posture: bpPostureOptions.contains(posture) ? posture : null,
      isDialysisDay: isDialysisDay,
      dialysisPhase: isDialysisDay == true &&
              bpDialysisPhaseOptions.contains(dialysisPhase)
          ? dialysisPhase
          : null,
    );
  }

  BloodPressureContext copyWith({
    String? Function()? arm,
    String? Function()? posture,
    bool? Function()? isDialysisDay,
    String? Function()? dialysisPhase,
  }) {
    return BloodPressureContext(
      arm: arm == null ? this.arm : arm(),
      posture: posture == null ? this.posture : posture(),
      isDialysisDay:
          isDialysisDay == null ? this.isDialysisDay : isDialysisDay(),
      dialysisPhase:
          dialysisPhase == null ? this.dialysisPhase : dialysisPhase(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BloodPressureContext &&
      other.arm == arm &&
      other.posture == posture &&
      other.isDialysisDay == isDialysisDay &&
      other.dialysisPhase == dialysisPhase;

  @override
  int get hashCode => Object.hash(arm, posture, isDialysisDay, dialysisPhase);
}
