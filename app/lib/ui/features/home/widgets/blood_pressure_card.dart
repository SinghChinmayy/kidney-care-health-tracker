import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBp =
        reading?.systolic != null && reading?.diastolic != null;
    final valueText = reading == null
        ? '—'
        : hasBp
            ? '${reading!.systolic}/${reading!.diastolic}'
            : reading!.heartRateBpm != null
                ? '${reading!.heartRateBpm}'
                : '—';
    final unitText = reading == null
        ? null
        : hasBp
            ? 'mmHg'
            : reading!.heartRateBpm != null
                ? 'bpm'
                : null;

    final subtitle = reading == null
        ? 'No reading yet'
        : [
            if (hasBp && reading!.heartRateBpm != null)
              '${reading!.heartRateBpm} bpm',
            formatHistoryTime(reading!.recordedAt),
          ].join(' · ');

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
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              valueText,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                                height: 1.0,
                                letterSpacing: -0.6,
                              ),
                            ),
                            if (unitText != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                unitText,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: _BloodPressureSparkline(
                      points: chartPoints,
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

class _BloodPressureSparkline extends StatelessWidget {
  const _BloodPressureSparkline({
    required this.points,
    required this.lineColor,
  });

  final List<BloodPressureHomeChartPoint> points;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BloodPressureSparklinePainter(
        points: points,
        lineColor: lineColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BloodPressureSparklinePainter extends CustomPainter {
  _BloodPressureSparklinePainter({
    required this.points,
    required this.lineColor,
  });

  final List<BloodPressureHomeChartPoint> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      final muted = Paint()
        ..color = AppTheme.muted.withValues(alpha: 0.2)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final y = size.height * 0.55;
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), muted);
      return;
    }

    final values = points.map((p) => p.systolic.toDouble()).toList();
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if ((maxV - minV).abs() < 1) {
      minV -= 10;
      maxV += 10;
    }
    final pad = (maxV - minV) * 0.15;
    minV -= pad;
    maxV += pad;

    double yFor(double value) {
      final t = ((value - minV) / (maxV - minV)).clamp(0.0, 1.0);
      return size.height * (0.85 - 0.7 * t);
    }

    final n = points.length;
    final xs = List<double>.generate(n, (i) {
      if (n == 1) return size.width * 0.5;
      return 8 + (size.width - 16) * (i / (n - 1));
    });

    final offsets = [
      for (var i = 0; i < n; i++)
        Offset(xs[i], yFor(points[i].systolic.toDouble())),
    ];

    if (offsets.length >= 2) {
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        path.lineTo(offsets[i].dx, offsets[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      final fillPath = Path.from(path)
        ..lineTo(offsets.last.dx, size.height)
        ..lineTo(offsets.first.dx, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, 0),
            Offset(0, size.height),
            [
              lineColor.withValues(alpha: 0.22),
              lineColor.withValues(alpha: 0.0),
            ],
          ),
      );
    }

    final end = offsets.last;
    canvas.drawCircle(
      end,
      4.5,
      Paint()..color = lineColor.withValues(alpha: 0.22),
    );
    canvas.drawCircle(end, 4.5, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _BloodPressureSparklinePainter oldDelegate) {
    if (oldDelegate.lineColor != lineColor ||
        oldDelegate.points.length != points.length) {
      return true;
    }
    for (var i = 0; i < points.length; i++) {
      final a = oldDelegate.points[i];
      final b = points[i];
      if (a.day != b.day || a.systolic != b.systolic) {
        return true;
      }
    }
    return false;
  }
}
