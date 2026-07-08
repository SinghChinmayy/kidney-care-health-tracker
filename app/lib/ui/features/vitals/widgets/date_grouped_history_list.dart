import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

typedef HistoryRowBuilder<T> = Widget Function(
  BuildContext context,
  T reading,
);

class DateGroupedHistoryList<T> extends StatelessWidget {
  const DateGroupedHistoryList({
    super.key,
    required this.readings,
    required this.recordedAt,
    required this.rowBuilder,
    this.emptyMessage = 'No readings yet.',
    this.accentColor = AppTheme.logWeight,
  });

  final List<T> readings;
  final DateTime Function(T reading) recordedAt;
  final HistoryRowBuilder<T> rowBuilder;
  final String emptyMessage;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final grouped = groupReadingsByLocalDate(readings, recordedAt);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      children: [
        for (final entry in grouped.entries) ...[
          _DateHeader(date: entry.key, accentColor: accentColor),
          for (final reading in entry.value)
            rowBuilder(context, reading),
          const SizedBox(height: AppTheme.spacingSm),
        ],
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.date,
    required this.accentColor,
  });

  final DateTime date;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingSm,
        bottom: AppTheme.spacingXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            formatHistoryDateHeader(date),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Container(height: 2, color: accentColor),
        ],
      ),
    );
  }
}

class VitalHistoryRow extends StatelessWidget {
  const VitalHistoryRow({
    super.key,
    required this.primaryText,
    required this.secondaryText,
    this.notes,
    this.onEdit,
    this.onDelete,
  });

  final String primaryText;
  final String secondaryText;
  final String? notes;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final hasActions = onEdit != null || onDelete != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  primaryText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                secondaryText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (hasActions) ...[
                const SizedBox(width: AppTheme.spacingXs),
                PopupMenuButton<_HistoryRowAction>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppTheme.muted,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _HistoryRowAction.edit:
                        onEdit?.call();
                      case _HistoryRowAction.delete:
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: _HistoryRowAction.edit,
                        child: Text('Edit'),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: _HistoryRowAction.delete,
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          if (notes != null && notes!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              notes!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _HistoryRowAction { edit, delete }
