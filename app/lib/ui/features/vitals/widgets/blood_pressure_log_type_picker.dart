import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/widgets/vital_option_row.dart';
import 'package:flutter/material.dart';

enum BloodPressureLogType { bloodPressure, heartRate, both }

class BloodPressureLogTypePicker extends StatelessWidget {
  const BloodPressureLogTypePicker({
    super.key,
    required this.logType,
    required this.onChanged,
    this.accentColor = AppTheme.logBloodPressure,
  });

  final BloodPressureLogType logType;
  final ValueChanged<BloodPressureLogType> onChanged;
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
        Text('LOG TYPE', style: labelStyle),
        const SizedBox(height: AppTheme.spacingXs),
        VitalOptionRow(
          options: const [
            VitalOption(value: 'blood_pressure', label: 'Blood pressure'),
            VitalOption(value: 'heart_rate', label: 'Heart rate'),
            VitalOption(value: 'both', label: 'Both'),
          ],
          selectedValue: switch (logType) {
            BloodPressureLogType.bloodPressure => 'blood_pressure',
            BloodPressureLogType.heartRate => 'heart_rate',
            BloodPressureLogType.both => 'both',
          },
          accentColor: accentColor,
          onSelected: (value) {
            final next = switch (value) {
              'heart_rate' => BloodPressureLogType.heartRate,
              'both' => BloodPressureLogType.both,
              _ => BloodPressureLogType.bloodPressure,
            };
            onChanged(next);
          },
        ),
      ],
    );
  }
}
