import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/home/widgets/vital_sparkline.dart';
import 'package:flutter/material.dart';

/// Compact home-screen tile widget for blood pressure.
///
/// Displays 7-day average systolic/diastolic with a smooth sparkline trend.
class BloodPressureWidget extends StatelessWidget {
  const BloodPressureWidget({
    super.key,
    required this.chartPoints,
    this.onTap,
  });

  final List<BloodPressureHomeChartPoint> chartPoints;
  final VoidCallback? onTap;

  // ── Computed display values ────────────────────────────────────────────────

  String get _averageText {
    final withBoth = chartPoints.where((p) => p.diastolic != null).toList();
    if (withBoth.isNotEmpty) {
      final avgSys = _avg(withBoth.map((p) => p.systolic.toDouble()));
      final avgDia = _avg(withBoth.map((p) => p.diastolic!.toDouble()));
      return '$avgSys/$avgDia';
    }
    if (chartPoints.isNotEmpty) {
      return '${_avg(chartPoints.map((p) => p.systolic.toDouble()))}';
    }
    return '—';
  }

  String get _unitText {
    if (chartPoints.any((p) => p.diastolic != null)) return 'mmHg';
    if (chartPoints.isNotEmpty) return 'sys';
    return '';
  }

  String get _subtitleText =>
      chartPoints.isEmpty ? 'No readings' : '${chartPoints.length}-day avg';

  List<double> get _sparklineValues =>
      chartPoints.map((p) => p.systolic.toDouble()).toList();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _VitalCompactTile(
      accentColor: AppTheme.logBloodPressure,
      icon: Icons.monitor_heart_outlined,
      title: 'Blood pressure',
      averageText: _averageText,
      unitText: _unitText,
      subtitleText: _subtitleText,
      sparklineValues: _sparklineValues,
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Compact home-screen tile widget for blood glucose.
///
/// Displays 7-day average mg/dL with a smooth sparkline trend.
class BloodGlucoseWidget extends StatelessWidget {
  const BloodGlucoseWidget({
    super.key,
    required this.chartPoints,
    this.onTap,
  });

  final List<BloodGlucoseHomeChartPoint> chartPoints;
  final VoidCallback? onTap;

  // ── Computed display values ────────────────────────────────────────────────

  String get _averageText {
    if (chartPoints.isEmpty) return '—';
    return '${_avg(chartPoints.map((p) => p.valueMgDl))}';
  }

  String get _unitText => chartPoints.isEmpty ? '' : 'mg/dL';

  String get _subtitleText =>
      chartPoints.isEmpty ? 'No readings' : '${chartPoints.length}-day avg';

  List<double> get _sparklineValues =>
      chartPoints.map((p) => p.valueMgDl).toList();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _VitalCompactTile(
      accentColor: AppTheme.logBloodGlucose,
      icon: Icons.water_drop_outlined,
      title: 'Blood glucose',
      averageText: _averageText,
      unitText: _unitText,
      subtitleText: _subtitleText,
      sparklineValues: _sparklineValues,
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared compact tile renderer
// ─────────────────────────────────────────────────────────────────────────────

/// Internal coloured tile used by both [BloodPressureWidget] and
/// [BloodGlucoseWidget].  Keeps all rendering logic in one place.
class _VitalCompactTile extends StatelessWidget {
  const _VitalCompactTile({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.averageText,
    required this.unitText,
    required this.subtitleText,
    required this.sparklineValues,
    this.onTap,
  });

  final Color accentColor;
  final IconData icon;
  final String title;
  final String averageText;
  final String unitText;
  final String subtitleText;
  final List<double> sparklineValues;
  final VoidCallback? onTap;

  static const Color _onBg = Colors.white;
  static const double _radius = AppTheme.cardCornerRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: AppTheme.homeCardDecoration(color: accentColor).copyWith(
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          borderRadius: BorderRadius.circular(_radius),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: _onBg),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _onBg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // Sparkline
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: VitalSparkline(
                      values: sparklineValues,
                      lineColor: _onBg,
                      onDarkBackground: true,
                    ),
                  ),
                ),
                // Value row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      averageText,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: _onBg,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        letterSpacing: -0.6,
                      ),
                    ),
                    if (unitText.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Text(
                        unitText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _onBg.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _onBg.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
