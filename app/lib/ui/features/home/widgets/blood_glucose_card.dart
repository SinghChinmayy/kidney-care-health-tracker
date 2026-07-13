import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/home/widgets/vital_sparkline.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_context_picker.dart';
import 'package:flutter/material.dart';

class BloodGlucoseCard extends StatelessWidget {
  const BloodGlucoseCard({
    super.key,
    required this.reading,
    required this.chartPoints,
    this.onTap,
  });

  final BloodGlucoseReading? reading;
  final List<BloodGlucoseHomeChartPoint> chartPoints;
  final VoidCallback? onTap;

  static const double _radius = AppTheme.cardCornerRadius;

  // ── Derived values ─────────────────────────────────────────────────────────

  String get _latestText => reading == null
      ? '—'
      : reading!.valueMgDl.toStringAsFixed(0);

  String get _subtitle => reading == null
      ? 'No reading yet'
      : [
          if (reading!.context != null && reading!.context!.isNotEmpty)
            formatBloodGlucoseContextLabel(reading!.context!),
          formatHistoryTime(reading!.recordedAt),
        ].join(' · ');

  /// 7-day average shown below the latest reading.
  String? get _avgText {
    if (chartPoints.isEmpty) return null;
    final avg = _avg(chartPoints.map((p) => p.valueMgDl));
    return '$avg mg/dL';
  }

  List<double> get _sparklineValues =>
      chartPoints.map((p) => p.valueMgDl).toList();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: SizedBox(
              height: 108,
              child: Row(
                children: [
                  // Left: labels + values
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              size: 18,
                              color: AppTheme.muted.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Blood glucose',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppTheme.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Latest reading
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _latestText,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                                height: 1.0,
                                letterSpacing: -0.6,
                              ),
                            ),
                            if (reading != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                'mg/dL',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Last-recorded subtitle
                        Text(
                          _subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // 7-day average
                        if (_avgText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '7d avg · $_avgText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.logBloodGlucose
                                  .withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right: sparkline
                  Expanded(
                    flex: 5,
                    child: VitalSparkline(
                      values: _sparklineValues,
                      lineColor: AppTheme.logBloodGlucose,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

int _avg(Iterable<double> values) {
  final list = values.toList();
  return (list.reduce((a, b) => a + b) / list.length).round();
}
