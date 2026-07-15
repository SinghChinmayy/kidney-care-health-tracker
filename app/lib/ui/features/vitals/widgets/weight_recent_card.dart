import 'package:app/domain/models/weight_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

class WeightRecentCard extends StatelessWidget {
  const WeightRecentCard({
    super.key,
    required this.reading,
    this.deltaKg,
    this.onTap,
  });

  final WeightReading reading;
  final double? deltaKg;
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

    final subtitle = formatWeightHistorySubtitle(
      dialysisTiming: reading.dialysisTiming,
      recordedAt: reading.recordedAt,
      weightContext: reading.weightContext,
    );

    final deltaLabel = deltaKg == null
        ? null
        : '${deltaKg! >= 0 ? '+' : ''}${deltaKg!.toStringAsFixed(1)} kg';
    final deltaColor = deltaKg == null
        ? AppTheme.muted
        : deltaKg! > 0.05
            ? AppTheme.error
            : deltaKg! < -0.05
                ? AppTheme.logWeight
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
                          reading.valueKg.toStringAsFixed(1),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kg',
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
