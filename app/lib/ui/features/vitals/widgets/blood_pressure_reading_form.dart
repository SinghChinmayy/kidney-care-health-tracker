import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_log_type_picker.dart';
import 'package:app/ui/features/vitals/widgets/numeric_stepper_input.dart';
import 'package:app/ui/features/vitals/widgets/vital_recorded_at_picker.dart';
import 'package:flutter/material.dart';

class BloodPressureReadingForm extends StatelessWidget {
  const BloodPressureReadingForm({
    super.key,
    required this.logType,
    required this.systolic,
    required this.diastolic,
    required this.heartRateBpm,
    required this.recordedAt,
    required this.onLogTypeChanged,
    required this.onSystolicChanged,
    required this.onDiastolicChanged,
    required this.onHeartRateChanged,
    required this.onRecordedAtChanged,
    this.accentColor = AppTheme.logBloodPressure,
    this.errorText,
  });

  final BloodPressureLogType logType;
  final int systolic;
  final int diastolic;
  final int heartRateBpm;
  final DateTime recordedAt;
  final ValueChanged<BloodPressureLogType> onLogTypeChanged;
  final ValueChanged<int> onSystolicChanged;
  final ValueChanged<int> onDiastolicChanged;
  final ValueChanged<int> onHeartRateChanged;
  final ValueChanged<DateTime> onRecordedAtChanged;
  final Color accentColor;
  final String? errorText;

  bool get _showBloodPressure =>
      logType == BloodPressureLogType.bloodPressure ||
      logType == BloodPressureLogType.both;

  bool get _showHeartRate =>
      logType == BloodPressureLogType.heartRate ||
      logType == BloodPressureLogType.both;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BloodPressureLogTypePicker(
          logType: logType,
          accentColor: accentColor,
          onChanged: onLogTypeChanged,
        ),
        if (_showBloodPressure) ...[
          const SizedBox(height: AppTheme.spacingMd),
          NumericStepperInput(
            label: 'Systolic (mmHg)',
            value: systolic.toDouble(),
            step: 1,
            min: 60,
            max: 250,
            decimals: 0,
            accentColor: accentColor,
            allowDirectInput: true,
            onChanged: (value) => onSystolicChanged(value.round()),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          NumericStepperInput(
            label: 'Diastolic (mmHg)',
            value: diastolic.toDouble(),
            step: 1,
            min: 40,
            max: 150,
            decimals: 0,
            accentColor: accentColor,
            allowDirectInput: true,
            onChanged: (value) => onDiastolicChanged(value.round()),
          ),
        ],
        if (_showHeartRate) ...[
          const SizedBox(height: AppTheme.spacingMd),
          NumericStepperInput(
            label: 'Heart rate (bpm)',
            value: heartRateBpm.toDouble(),
            step: 1,
            min: 30,
            max: 220,
            decimals: 0,
            accentColor: accentColor,
            allowDirectInput: true,
            onChanged: (value) => onHeartRateChanged(value.round()),
          ),
        ],
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
