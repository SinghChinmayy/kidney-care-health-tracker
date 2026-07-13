import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

typedef WeekHistoryRowBuilder<T> = Widget Function(
  BuildContext context,
  T reading,
);

class WeekGroupedHistoryList<T> extends StatefulWidget {
  const WeekGroupedHistoryList({
    super.key,
    required this.readings,
    required this.recordedAt,
    required this.rowBuilder,
    this.maxPerWeek = 3,
  });

  final List<T> readings;
  final DateTime Function(T reading) recordedAt;
  final WeekHistoryRowBuilder<T> rowBuilder;
  final int maxPerWeek;

  @override
  State<WeekGroupedHistoryList<T>> createState() =>
      _WeekGroupedHistoryListState<T>();
}

class _WeekGroupedHistoryListState<T> extends State<WeekGroupedHistoryList<T>> {
  final Set<DateTime> _expandedWeeks = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = groupReadingsByWeekStart(
      widget.readings,
      widget.recordedAt,
    );

    final widgets = <Widget>[];
    var weekIndex = 0;

    for (final entry in grouped.entries) {
      final weekStart = entry.key;
      final weekReadings = entry.value;
      final expanded = _expandedWeeks.contains(weekStart);
      final shown = expanded
          ? weekReadings
          : weekReadings.take(widget.maxPerWeek).toList();
      final hidden = weekReadings.length - shown.length;

      if (weekIndex > 0) {
        widgets.add(const SizedBox(height: AppTheme.spacingSm));
      }

      widgets.add(
        Text(
          formatWeekGroupLabel(weekStart),
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
      widgets.add(const SizedBox(height: AppTheme.spacingXs));

      for (final reading in shown) {
        widgets.add(widget.rowBuilder(context, reading));
        widgets.add(const SizedBox(height: AppTheme.spacingXs));
      }

      if (hidden > 0) {
        widgets.add(
          _ShowMoreRow(
            count: hidden,
            onTap: () => setState(() => _expandedWeeks.add(weekStart)),
          ),
        );
        widgets.add(const SizedBox(height: AppTheme.spacingXs));
      }

      weekIndex++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}

class _ShowMoreRow extends StatelessWidget {
  const _ShowMoreRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cardCornerRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.muted.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(AppTheme.cardCornerRadius),
        ),
        child: Text(
          '+ $count more reading${count == 1 ? '' : 's'}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
