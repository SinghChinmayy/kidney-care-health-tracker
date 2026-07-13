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
    this.dense = false,
  });

  final List<T> readings;
  final DateTime Function(T reading) recordedAt;
  final WeekHistoryRowBuilder<T> rowBuilder;
  final int maxPerWeek;
  final bool dense;

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
    final weekGap = widget.dense ? 8.0 : AppTheme.spacingSm;
    final rowGap = widget.dense ? 0.0 : AppTheme.spacingXs;

    for (final entry in grouped.entries) {
      final weekStart = entry.key;
      final weekReadings = entry.value;
      final expanded = _expandedWeeks.contains(weekStart);
      final shown = expanded
          ? weekReadings
          : weekReadings.take(widget.maxPerWeek).toList();
      final hidden = weekReadings.length - shown.length;

      if (weekIndex > 0) {
        widgets.add(SizedBox(height: weekGap));
      }

      widgets.add(
        Text(
          formatWeekGroupLabel(weekStart),
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      );
      widgets.add(SizedBox(height: widget.dense ? 4 : AppTheme.spacingXs));

      for (final reading in shown) {
        widgets.add(widget.rowBuilder(context, reading));
        if (rowGap > 0) {
          widgets.add(SizedBox(height: rowGap));
        }
      }

      if (hidden > 0) {
        widgets.add(
          _ShowMoreRow(
            count: hidden,
            onTap: () => setState(() => _expandedWeeks.add(weekStart)),
            dense: widget.dense,
          ),
        );
        if (rowGap > 0) {
          widgets.add(SizedBox(height: rowGap));
        }
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
  const _ShowMoreRow({
    required this.count,
    required this.onTap,
    this.dense = false,
  });

  final int count;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cardCornerRadius),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: dense ? 6 : 10,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.muted.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(
            dense ? 10 : AppTheme.cardCornerRadius,
          ),
        ),
        child: Text(
          '+ $count more',
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
