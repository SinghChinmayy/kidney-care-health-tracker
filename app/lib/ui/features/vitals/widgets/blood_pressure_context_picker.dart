import 'package:app/domain/models/blood_pressure_context.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:app/ui/features/vitals/widgets/vital_option_row.dart';
import 'package:flutter/material.dart';

const _notSet = 'Not set';

/// Optional arm / posture / dialysis context for a BP reading.
///
/// Collapsed by default so the quick-log flow stays short; opens
/// automatically when the reading already has context.
class BloodPressureContextPicker extends StatelessWidget {
  const BloodPressureContextPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.accentColor = AppTheme.logBloodPressure,
  });

  final BloodPressureContext value;
  final ValueChanged<BloodPressureContext> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: AppTheme.muted,
      fontWeight: FontWeight.w600,
    );
    final summary = formatBloodPressureContextSummary(value);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const ValueKey('bp-context-picker'),
        initiallyExpanded: !value.isEmpty,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: Text(
          'Measurement details',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          summary ?? 'Optional: arm, posture, dialysis day',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.muted),
        ),
        children: [
          Text('Arm', style: labelStyle),
          const SizedBox(height: 6),
          VitalOptionRow(
            options: [
              const VitalOption(value: null, label: _notSet),
              for (final arm in bpArmOptions)
                VitalOption(value: arm, label: formatBpArmLabel(arm)),
            ],
            selectedValue: value.arm,
            accentColor: accentColor,
            onSelected: (arm) => onChanged(value.copyWith(arm: () => arm)),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text('Posture', style: labelStyle),
          const SizedBox(height: 6),
          VitalOptionRow(
            options: [
              const VitalOption(value: null, label: _notSet),
              for (final posture in bpPostureOptions)
                VitalOption(
                  value: posture,
                  label: formatBpPostureLabel(posture),
                ),
            ],
            selectedValue: value.posture,
            accentColor: accentColor,
            onSelected: (posture) =>
                onChanged(value.copyWith(posture: () => posture)),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text('Dialysis day', style: labelStyle),
          const SizedBox(height: 6),
          VitalOptionRow(
            options: const [
              VitalOption(value: null, label: _notSet),
              VitalOption(value: 'yes', label: 'Yes'),
              VitalOption(value: 'no', label: 'No'),
            ],
            selectedValue: switch (value.isDialysisDay) {
              true => 'yes',
              false => 'no',
              null => null,
            },
            accentColor: accentColor,
            onSelected: (selected) {
              final isDialysisDay = switch (selected) {
                'yes' => true,
                'no' => false,
                _ => null,
              };
              onChanged(
                value.copyWith(
                  isDialysisDay: () => isDialysisDay,
                  dialysisPhase: () =>
                      isDialysisDay == true ? value.dialysisPhase : null,
                ),
              );
            },
          ),
          if (value.isDialysisDay == true) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text('Timing', style: labelStyle),
            const SizedBox(height: 6),
            VitalOptionRow(
              options: [
                const VitalOption(value: null, label: _notSet),
                for (final phase in bpDialysisPhaseOptions)
                  VitalOption(
                    value: phase,
                    label: formatBpDialysisPhaseLabel(phase),
                  ),
              ],
              selectedValue: value.dialysisPhase,
              accentColor: accentColor,
              onSelected: (phase) =>
                  onChanged(value.copyWith(dialysisPhase: () => phase)),
            ),
          ],
        ],
      ),
    );
  }
}
