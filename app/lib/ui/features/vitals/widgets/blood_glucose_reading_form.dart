import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_context_picker.dart';
import 'package:app/ui/features/vitals/widgets/numeric_stepper_input.dart';
import 'package:app/ui/features/vitals/widgets/vital_recorded_at_picker.dart';
import 'package:flutter/material.dart';

class BloodGlucoseReadingForm extends StatelessWidget {
  const BloodGlucoseReadingForm({
    super.key,
    required this.valueMgDl,
    required this.selectedContext,
    required this.recordedAt,
    required this.onValueChanged,
    required this.onContextChanged,
    required this.onRecordedAtChanged,
    this.accentColor = AppTheme.logBloodGlucose,
    this.errorText,
  });

  final double valueMgDl;
  final String? selectedContext;
  final DateTime recordedAt;
  final ValueChanged<double> onValueChanged;
  final ValueChanged<String?> onContextChanged;
  final ValueChanged<DateTime> onRecordedAtChanged;
  final Color accentColor;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NumericStepperInput(
          label: 'Glucose (mg/dL)',
          value: valueMgDl,
          step: 1,
          min: 20,
          max: 600,
          decimals: 0,
          accentColor: accentColor,
          allowDirectInput: true,
          onChanged: onValueChanged,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        BloodGlucoseContextPicker(
          selectedContext: selectedContext,
          accentColor: accentColor,
          onChanged: onContextChanged,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        VitalRecordedAtPicker(
          recordedAt: recordedAt,
          accentColor: accentColor,
          onChanged: onRecordedAtChanged,
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Text(errorText!, style: TextStyle(color: AppTheme.error)),
        ],
      ],
    );
  }
}
