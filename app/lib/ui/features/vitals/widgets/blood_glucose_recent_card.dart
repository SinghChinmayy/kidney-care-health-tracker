import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_context_picker.dart';
import 'package:flutter/material.dart';

class BloodGlucoseRecentCard extends StatelessWidget {
  const BloodGlucoseRecentCard({
    super.key,
    required this.reading,
    this.deltaMgDl,
    this.onTap,
  });

  final BloodGlucoseReading reading;
  final double? deltaMgDl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = reading.recordedAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final yesterday = todayDay.subtract(const Duration(days: 1));

    final title = day == todayDay
        ? 'Today'
        : day == yesterday
            ? 'Yesterday'
            : formatHistoryDateHeader(day);

    final subtitle = formatBloodGlucoseHistorySubtitle(
      recordedAt: reading.recordedAt,
      context: reading.context,
    );

    final deltaLabel = deltaMgDl == null
        ? null
        : '${deltaMgDl! >= 0 ? '+' : ''}${deltaMgDl!.toStringAsFixed(0)}';
    final deltaColor = deltaMgDl == null
        ? AppTheme.muted
        : deltaMgDl! > 5
            ? AppTheme.error
            : deltaMgDl! < -5
                ? AppTheme.logBloodGlucose
                : AppTheme.muted;

    return Material(
      color: AppTheme.cardSurface,
      borderRadius: BorderRadius.circular(AppTheme.cardCornerRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardCornerRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          reading.valueMgDl.toStringAsFixed(0),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'mg/dL',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (deltaLabel != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            deltaLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: deltaColor,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppTheme.muted.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatBloodGlucoseHistorySubtitle({
  required DateTime recordedAt,
  String? context,
}) {
  final parts = <String>[
    formatHistoryTime(recordedAt),
  ];
  if (context != null && context.isNotEmpty) {
    parts.add(formatBloodGlucoseContextLabel(context));
  }
  return parts.join(' · ');
}
