import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/models/weight_period.dart';
import 'package:flutter/material.dart';

class WeightPeriodSelector extends StatelessWidget {
  const WeightPeriodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final WeightPeriod selected;
  final ValueChanged<WeightPeriod> onSelected;

  static const _options = <(WeightPeriod, String)>[
    (WeightPeriod.week, 'W'),
    (WeightPeriod.month, 'M'),
    (WeightPeriod.year, 'Y'),
    (WeightPeriod.all, 'All'),
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
