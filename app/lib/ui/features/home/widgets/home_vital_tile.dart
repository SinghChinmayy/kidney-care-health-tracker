import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Compact vital summary card for the home 2×2 grid.
///
/// Primary tap opens the log sheet; [onHistoryTap] opens the detail view.
class HomeVitalTile extends StatelessWidget {
  const HomeVitalTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    required this.onHistoryTap,
    this.unit,
    this.accentColor,
    this.isLogged = false,
    this.progress,
    this.progressOverGoal = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? unit;
  final VoidCallback onTap;
  final VoidCallback onHistoryTap;
  final Color? accentColor;
  final bool isLogged;

  /// Optional 0..1 ring progress (e.g. water vs goal).
  final double? progress;
  final bool progressOverGoal;

  static const double _radius = AppTheme.cardCornerRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? AppTheme.ink;
    final hasReading = value != 'No readings yet';

    return Material(
      color: AppTheme.cardSurface,
      borderRadius: BorderRadius.circular(_radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  if (isLogged)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(Icons.check_circle, size: 16, color: accent),
                    ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'History',
                      onPressed: onHistoryTap,
                      icon: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppTheme.muted.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (progress != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _ValueBlock(
                        theme: theme,
                        value: value,
                        unit: unit,
                        hasReading: hasReading,
                        emphasizeError: progressOverGoal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppTheme.ink.withValues(alpha: 0.08),
                        color: progressOverGoal ? AppTheme.error : accent,
                      ),
                    ),
                  ],
                )
              else
                _ValueBlock(
                  theme: theme,
                  value: value,
                  unit: unit,
                  hasReading: hasReading,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({
    required this.theme,
    required this.value,
    required this.hasReading,
    this.unit,
    this.emphasizeError = false,
  });

  final ThemeData theme;
  final String value;
  final String? unit;
  final bool hasReading;
  final bool emphasizeError;

  @override
  Widget build(BuildContext context) {
    if (!hasReading) {
      return Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.muted,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final valueColor = emphasizeError ? AppTheme.error : AppTheme.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
            height: 1.05,
            letterSpacing: -0.4,
          ),
        ),
        if (unit != null && unit!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            unit!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: emphasizeError
                  ? AppTheme.error.withValues(alpha: 0.8)
                  : AppTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
