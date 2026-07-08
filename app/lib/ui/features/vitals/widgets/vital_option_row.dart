import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class VitalOption {
  const VitalOption({required this.value, required this.label});

  final String? value;
  final String label;
}

class VitalOptionRow extends StatelessWidget {
  const VitalOptionRow({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.accentColor,
    required this.onSelected,
  });

  final List<VitalOption> options;
  final String? selectedValue;
  final Color accentColor;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingXs,
      runSpacing: AppTheme.spacingXs,
      children: options.map((option) {
        final isSelected = selectedValue == option.value;
        return OutlinedButton(
          onPressed: () => onSelected(option.value),
          style: OutlinedButton.styleFrom(
            foregroundColor: isSelected ? accentColor : AppTheme.ink,
            backgroundColor: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : Colors.transparent,
            side: BorderSide(
              color: isSelected
                  ? accentColor
                  : AppTheme.muted.withValues(alpha: 0.4),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: AppTheme.spacingXs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
            ),
          ),
          child: Text(option.label),
        );
      }).toList(),
    );
  }
}
