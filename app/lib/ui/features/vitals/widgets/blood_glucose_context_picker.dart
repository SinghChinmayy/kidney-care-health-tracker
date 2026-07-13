import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_forms.dart';
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
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Context', style: labelStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _ContextChip(
              label: 'None',
              selected: selectedContext == null,
              accentColor: accentColor,
              onTap: () => onChanged(null),
            ),
            ...bloodGlucoseContextOptions.map(
              (option) => _ContextChip(
                label: formatBloodGlucoseContextLabel(option),
                selected: selectedContext == option,
                accentColor: accentColor,
                onTap: () => onChanged(option),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selectedColor: accentColor.withValues(alpha: 0.14),
      side: BorderSide(
        color: selected
            ? accentColor.withValues(alpha: 0.55)
            : AppTheme.muted.withValues(alpha: 0.28),
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? accentColor : AppTheme.ink,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
      onSelected: (_) => onTap(),
    );
  }
}
