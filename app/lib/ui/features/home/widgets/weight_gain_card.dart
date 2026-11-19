import 'package:app/domain/models/weight_gain_from_dry_weight.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class WeightGainCard extends StatelessWidget {
  const WeightGainCard({
    super.key,
    required this.snapshot,
    this.onTap,
  });

  final WeightGainSnapshot snapshot;

  /// Opens weight tracking when the card is tapped.
  final VoidCallback? onTap;

  static const double _radius = AppTheme.cardCornerRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gain = snapshot.gainKg;
    final gainColor = gain == null
        ? AppTheme.muted
        : gain > 0.05
            ? AppTheme.error
            : AppTheme.ink;

    final valueText = gain == null
        ? '—'
        : '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(1)}';
    final showUnit = gain != null;

    final post = snapshot.postDialysis;
    final current = snapshot.current;
    final showSupportLines = post != null;

    final dryLabel = post == null
        ? null
        : 'Dry weight ${post.valueKg.toStringAsFixed(1)} kg';
    final latestLabel = showSupportLines
        ? (current == null
            ? 'Latest —'
            : 'Latest ${current.valueKg.toStringAsFixed(1)} kg')
        : null;

    return DecoratedBox(
      decoration: AppTheme.homeCardDecoration(color: AppTheme.cardSurface),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monitor_weight_outlined,
                      size: 18,
                      color: AppTheme.muted.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Weight gain',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      valueText,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: gainColor,
                        height: 1.0,
                        letterSpacing: -0.6,
                      ),
                    ),
                    if (showUnit) ...[
                      const SizedBox(width: 6),
                      Text(
                        'kg',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (dryLabel != null && latestLabel != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    dryLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    latestLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
