import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/models/blood_pressure_period.dart';
import 'package:flutter/material.dart';

class BloodPressurePeriodSelector extends StatelessWidget {
  const BloodPressurePeriodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final BloodPressurePeriod selected;
  final ValueChanged<BloodPressurePeriod> onSelected;

  static const _options = <(BloodPressurePeriod, String)>[
    (BloodPressurePeriod.last7Days, '7D'),
    (BloodPressurePeriod.last30Days, '30D'),
    (BloodPressurePeriod.month, 'Month'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final (period, label) in _options)
            Expanded(
              child: _PeriodChip(
                label: label,
                selected: period == selected,
                onTap: () => onSelected(period),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppTheme.background : AppTheme.muted,
                ),
          ),
        ),
      ),
    );
  }
}
