import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/widgets/numeric_stepper_input.dart';
import 'package:app/ui/features/vitals/widgets/vital_option_row.dart';
import 'package:app/ui/features/vitals/widgets/vital_recorded_at_picker.dart';
import 'package:flutter/material.dart';

const fluidIntakeQuickAmountsMl = [100.0, 150.0, 200.0, 250.0, 500.0];

class FluidIntakeReadingForm extends StatelessWidget {
  const FluidIntakeReadingForm({
    super.key,
    required this.fluidMl,
    required this.recordedAt,
    required this.onFluidMlChanged,
    required this.onRecordedAtChanged,
    this.accentColor = AppTheme.logFluidIntake,
    this.errorText,
  });

  final double fluidMl;
  final DateTime recordedAt;
  final ValueChanged<double> onFluidMlChanged;
  final ValueChanged<DateTime> onRecordedAtChanged;
  final Color accentColor;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final quickOptions = [
      for (final amount in fluidIntakeQuickAmountsMl)
        VitalOption(
          value: amount.toStringAsFixed(0),
          label: '${amount.toStringAsFixed(0)} ml',
        ),
    ];
    final selectedQuick = fluidIntakeQuickAmountsMl.contains(fluidMl)
        ? fluidMl.toStringAsFixed(0)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NumericStepperInput(
          label: 'Amount (ml)',
          value: fluidMl,
          step: 50,
          min: 50,
          max: 2000,
          decimals: 0,
          accentColor: accentColor,
          unitSuffix: 'ml',
          allowDirectInput: true,
          onChanged: onFluidMlChanged,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          'Quick add',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        VitalOptionRow(
          options: quickOptions,
          selectedValue: selectedQuick,
          accentColor: accentColor,
          onSelected: (value) {
            if (value == null) {
              return;
            }
            onFluidMlChanged(double.parse(value));
          },
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
