import 'package:app/domain/models/weight_gain_from_dry_weight.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

class WeightGainCard extends StatelessWidget {
  const WeightGainCard({
    super.key,
    required this.weightGain,
    this.onTap,
  });

  final WeightGainFromDryWeight? weightGain;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gain = weightGain;

    return Material(
      color: AppTheme.surfaceMuted,
      borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
            border: Border.all(color: AppTheme.ink.withValues(alpha: 0.12)),
          ),
          child: gain == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight since dialysis',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log a post-dialysis weight, then a non-dialysis or random check',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight since dialysis',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      gain.displayGain,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: gain.gainKg > 0
                            ? AppTheme.error
                            : AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From ${gain.postDialysis.displayValue} post-dialysis '
                      'to ${gain.current.displayValue}'
                      '${_currentEntrySuffix(gain)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTrackRecordedAt(gain.current.recordedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _currentEntrySuffix(WeightGainFromDryWeight gain) {
    if (gain.current.weightContext == weightContextRandom) {
      return ' (random)';
    }
    return '';
  }
}
