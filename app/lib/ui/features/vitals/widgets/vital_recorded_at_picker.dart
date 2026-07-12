import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

class VitalRecordedAtPicker extends StatelessWidget {
  const VitalRecordedAtPicker({
    super.key,
    required this.recordedAt,
    required this.onChanged,
    this.accentColor = AppTheme.logWeight,
    this.compact = false,
  });

  final DateTime recordedAt;
  final ValueChanged<DateTime> onChanged;
  final Color accentColor;
  final bool compact;

  Future<void> _pickDateTime(BuildContext context) async {
    final local = recordedAt.toLocal();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: local,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (!context.mounted || pickedDate == null) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(local),
    );
    if (!context.mounted || pickedTime == null) {
      return;
    }

    onChanged(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: () => _pickDateTime(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.ink,
        side: BorderSide(
          color: AppTheme.muted.withValues(alpha: compact ? 0.28 : 1),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: compact ? 12 : AppTheme.spacingSm,
        ),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            color: accentColor,
            size: compact ? 18 : 20,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Expanded(
            child: Text(
              formatTrackRecordedAt(recordedAt),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: compact ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: AppTheme.muted.withValues(alpha: 0.55),
          ),
        ],
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'When',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          button,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'WHEN',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Container(
          height: 2,
          color: accentColor,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        button,
      ],
    );
  }
}
