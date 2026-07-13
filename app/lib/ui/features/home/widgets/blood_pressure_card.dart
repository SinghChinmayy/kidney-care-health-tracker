import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/home/widgets/vital_sparkline.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

class BloodPressureCard extends StatelessWidget {
  const BloodPressureCard({
    super.key,
    required this.reading,
    required this.chartPoints,
    this.onTap,
  });

  final BloodPressureReading? reading;
  final List<BloodPressureHomeChartPoint> chartPoints;
  final VoidCallback? onTap;

  static const double _radius = AppTheme.cardCornerRadius;

  // ── Derived values ─────────────────────────────────────────────────────────

  bool get _hasBp => reading?.systolic != null && reading?.diastolic != null;

  String get _latestText => reading == null
      ? '—'
      : _hasBp
          ? '${reading!.systolic}/${reading!.diastolic}'
          : reading!.heartRateBpm != null
              ? '${reading!.heartRateBpm}'
              : '—';

  String? get _latestUnit => reading == null
      ? null
      : _hasBp
          ? 'mmHg'
          : reading!.heartRateBpm != null
              ? 'bpm'
              : null;

  String get _subtitle => reading == null
      ? 'No reading yet'
      : [
          if (_hasBp && reading!.heartRateBpm != null)
            '${reading!.heartRateBpm} bpm',
          formatHistoryTime(reading!.recordedAt),
        ].join(' · ');

  /// 7-day average shown below the latest reading.
  String? get _avgText {
    final withBoth = chartPoints.where((p) => p.diastolic != null).toList();
    if (withBoth.isNotEmpty) {
      final avgSys = _avg(withBoth.map((p) => p.systolic.toDouble()));
      final avgDia = _avg(withBoth.map((p) => p.diastolic!.toDouble()));
      return '$avgSys/$avgDia mmHg';
    }
    if (chartPoints.isNotEmpty) {
      return '${_avg(chartPoints.map((p) => p.systolic.toDouble()))} sys';
    }
    return null;
  }

  List<double> get _sparklineValues =>
      chartPoints.map((p) => p.systolic.toDouble()).toList();

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
                              Icons.monitor_heart_outlined,
                              size: 18,
                              color: AppTheme.muted.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Blood pressure',
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
                            if (_latestUnit != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                _latestUnit!,
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
                              color: AppTheme.logBloodPressure
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
                      lineColor: AppTheme.logBloodPressure,
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
