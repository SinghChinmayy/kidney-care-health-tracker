import 'package:app/domain/models/weight_reading_options.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/widgets/numeric_stepper_input.dart';
import 'package:app/ui/features/vitals/widgets/vital_recorded_at_picker.dart';
import 'package:app/ui/features/vitals/widgets/weight_dialysis_picker.dart';
import 'package:flutter/material.dart';

class WeightReadingForm extends StatelessWidget {
  const WeightReadingForm({
    super.key,
    required this.valueKg,
    required this.dialysisTiming,
    required this.weightContext,
    required this.recordedAt,
    required this.notesController,
    required this.onValueKgChanged,
    required this.onDialysisTimingChanged,
    required this.onWeightContextChanged,
    required this.onRecordedAtChanged,
    this.accentColor = AppTheme.logWeight,
  });

  final double valueKg;
  final String dialysisTiming;
  final String? weightContext;
  final DateTime recordedAt;
  final TextEditingController notesController;
  final ValueChanged<double> onValueKgChanged;
  final ValueChanged<String> onDialysisTimingChanged;
  final ValueChanged<String?> onWeightContextChanged;
  final ValueChanged<DateTime> onRecordedAtChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NumericStepperInput(
          label: 'Weight (kg)',
          value: valueKg,
          step: 0.5,
          min: 0.5,
          max: 300,
          decimals: 1,
          accentColor: accentColor,
          allowDirectInput: true,
          onChanged: onValueKgChanged,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        WeightDialysisPicker(
          dialysisTiming: dialysisTiming,
          weightContext: weightContext,
          accentColor: accentColor,
          onDialysisTimingChanged: onDialysisTimingChanged,
          onWeightContextChanged: onWeightContextChanged,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        VitalRecordedAtPicker(
          recordedAt: recordedAt,
          accentColor: accentColor,
          onChanged: onRecordedAtChanged,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          controller: notesController,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
          maxLines: 2,
        ),
      ],
    );
  }
}

/// Initial draft values from an existing [WeightReading] or defaults for new entry.
WeightReadingDraft weightReadingDraftFrom({
  double? valueKg,
  String? dialysisTiming,
  String? weightContext,
  DateTime? recordedAt,
  String? notes,
}) {
  return WeightReadingDraft(
    valueKg: valueKg ?? 70.0,
    dialysisTiming: dialysisTiming ?? dialysisTimingNonDialysis,
    weightContext: weightContext,
    recordedAt: recordedAt ?? DateTime.now(),
    notes: notes,
  );
}

class WeightReadingDraft {
  const WeightReadingDraft({
    required this.valueKg,
    required this.dialysisTiming,
    required this.recordedAt,
    this.weightContext,
    this.notes,
  });

  final double valueKg;
  final String dialysisTiming;
  final String? weightContext;
  final DateTime recordedAt;
  final String? notes;
}
