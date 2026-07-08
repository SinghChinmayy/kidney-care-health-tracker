import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_forms.dart';
import 'package:app/ui/features/vitals/widgets/vital_option_row.dart';
import 'package:flutter/material.dart';

String formatBloodGlucoseContextLabel(String context) {
  return switch (context) {
    'fasting' => 'Fasting',
    'post_meal' => 'Post meal',
    'random' => 'Random',
    'bedtime' => 'Bedtime',
    _ => context.replaceAll('_', ' '),
  };
}

class BloodGlucoseContextPicker extends StatelessWidget {
  const BloodGlucoseContextPicker({
    super.key,
    required this.selectedContext,
    required this.onChanged,
    this.accentColor = AppTheme.logBloodGlucose,
  });

  final String? selectedContext;
  final ValueChanged<String?> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTheme.muted,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('CONTEXT (OPTIONAL)', style: labelStyle),
        const SizedBox(height: AppTheme.spacingXs),
        VitalOptionRow(
          options: [
            const VitalOption(value: null, label: 'None'),
            ...bloodGlucoseContextOptions.map(
              (option) => VitalOption(
                value: option,
                label: formatBloodGlucoseContextLabel(option),
              ),
            ),
          ],
          selectedValue: selectedContext,
          accentColor: accentColor,
          onSelected: onChanged,
        ),
      ],
    );
  }
}
