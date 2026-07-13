import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/domain/models/weight_gain_from_dry_weight.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class WeightGainCard extends StatelessWidget {
  const WeightGainCard({
    super.key,
    required this.snapshot,
    required this.chart,
    this.onTap,
  });

  final WeightGainSnapshot snapshot;
  final WeightGainChartData chart;

  /// Opens weight tracking when the card is tapped.
  final VoidCallback? onTap;

  static const double _radius = AppTheme.cardCornerRadius;
  static const Color _weightLine = Color(0xFF9B8CE8);
  static const Color _dryLine = Color(0xFF4DB6AC);

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

    return DecoratedBox(
      decoration: AppTheme.homeCardDecoration(color: AppTheme.background),
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
                            const SizedBox(width: 6),
                            _WeightGainChartHelpButton(
                              weightColor: _weightLine,
                              dryColor: _dryLine,
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppTheme.cardSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _trendIcon(snapshot),
                                size: 12,
                                color: AppTheme.muted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                snapshot.trendLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppTheme.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: _WeightGainSparkline(
                      chart: chart,
                      weightColor: _weightLine,
                      dryColor: _dryLine,
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

  IconData _trendIcon(WeightGainSnapshot snapshot) {
    switch (snapshot.status) {
      case WeightGainStatus.empty:
        return Icons.add_circle_outline;
      case WeightGainStatus.awaitingCurrent:
        return Icons.radio_button_unchecked;
      case WeightGainStatus.paired:
        final direction = snapshot.trendDirection;
        if (direction > 0) return Icons.arrow_upward;
        if (direction < 0) return Icons.arrow_downward;
        return Icons.horizontal_rule;
    }
  }
}

class _WeightGainChartHelpButton extends StatelessWidget {
  const _WeightGainChartHelpButton({
    required this.weightColor,
    required this.dryColor,
  });

  final Color weightColor;
  final Color dryColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardSurface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _showChartHelp(context),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.muted,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showChartHelp(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle.noAnimation,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: AppTheme.sheetTopRadius,
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingSm,
              AppTheme.spacingXs,
              AppTheme.spacingSm,
              AppTheme.spacingMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'About this chart',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'This chart shows weight change since your last '
                  'post-dialysis (dry) weight.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _ChartHelpLegendRow(
                  color: dryColor,
                  title: 'Dry weight baseline',
                  body:
                      'Your most recent post-dialysis weight on or before the '
                      'selected day. This is used as the dry-weight baseline — '
                      'not a separate target stored in your profile.',
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _ChartHelpLegendRow(
                  color: weightColor,
                  title: 'Weight trajectory',
                  body:
                      'Weights logged after that post-dialysis reading, up '
                      'through the selected day. The highlighted point is the '
                      'latest reading in this period.',
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'The big number is how much you are above or below that '
                  'dry-weight baseline right now.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.ink,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChartHelpLegendRow extends StatelessWidget {
  const _ChartHelpLegendRow({
    required this.color,
    required this.title,
    required this.body,
  });

  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightGainSparkline extends StatelessWidget {
  const _WeightGainSparkline({
    required this.chart,
    required this.weightColor,
    required this.dryColor,
  });

  final WeightGainChartData chart;
  final Color weightColor;
  final Color dryColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WeightGainSparklinePainter(
        chart: chart,
        weightColor: weightColor,
        dryColor: dryColor,
        axisColor: AppTheme.muted.withValues(alpha: 0.35),
        guideColor: AppTheme.muted.withValues(alpha: 0.25),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _WeightGainSparklinePainter extends CustomPainter {
  _WeightGainSparklinePainter({
    required this.chart,
    required this.weightColor,
    required this.dryColor,
    required this.axisColor,
    required this.guideColor,
  });

  final WeightGainChartData chart;
  final Color weightColor;
  final Color dryColor;
  final Color axisColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final axisY = size.height - 10;
    _drawAxis(canvas, size, axisY);

    if (!chart.hasSeries) {
      _drawPlaceholder(canvas, size, axisY);
      return;
    }

    final dry = chart.dryWeightKg!;
    final weights = chart.weights;
    final values = [dry, ...weights.map((p) => p.valueKg)];
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if ((maxV - minV).abs() < 0.2) {
      minV -= 0.5;
      maxV += 0.5;
    }
    final pad = (maxV - minV) * 0.18;
    minV -= pad;
    maxV += pad;

    double yFor(double value) {
      final t = (value - minV) / (maxV - minV);
      return ui.lerpDouble(axisY - 8, 8, t)!;
    }

    final n = weights.length;
    final xs = List<double>.generate(n, (i) {
      if (n == 1) return size.width * 0.82;
      return 4 + (size.width - 16) * (i / (n - 1));
    });
    final points = <Offset>[
      for (var i = 0; i < n; i++) Offset(xs[i], yFor(weights[i].valueKg)),
    ];

    // Dry-weight baseline (teal).
    final dryY = yFor(dry);
    final dryPaint = Paint()
      ..color = dryColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(4, dryY),
      Offset(size.width - 8, dryY),
      dryPaint,
    );
    canvas.drawCircle(
      Offset(size.width - 8, dryY),
      3.5,
      Paint()..color = dryColor,
    );

    // Weight trajectory (lavender).
    if (points.length == 1) {
      canvas.drawCircle(points.first, 4, Paint()..color = weightColor);
    } else {
      final path = _smoothPath(points);
      canvas.drawPath(
        path,
        Paint()
          ..color = weightColor
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final end = points.last;
    canvas.drawCircle(
      end,
      9,
      Paint()..color = weightColor.withValues(alpha: 0.22),
    );
    canvas.drawCircle(end, 4.5, Paint()..color = weightColor);

    final guidePaint = Paint()
      ..color = guideColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 3.0;
    var y = end.dy + 6;
    while (y < axisY) {
      canvas.drawLine(
        Offset(end.dx, y),
        Offset(end.dx, math.min(y + dash, axisY)),
        guidePaint,
      );
      y += dash * 2;
    }
  }

  void _drawAxis(Canvas canvas, Size size, double axisY) {
    final paint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(4, axisY), Offset(size.width - 4, axisY), paint);
    const ticks = 5;
    for (var i = 0; i < ticks; i++) {
      final x = 4 + (size.width - 8) * (i / (ticks - 1));
      canvas.drawLine(Offset(x, axisY), Offset(x, axisY + 4), paint);
    }
  }

  void _drawPlaceholder(Canvas canvas, Size size, double axisY) {
    final path = Path()
      ..moveTo(8, axisY - 18)
      ..cubicTo(
        size.width * 0.3,
        axisY - 28,
        size.width * 0.55,
        axisY - 12,
        size.width - 12,
        axisY - 36,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.muted.withValues(alpha: 0.2)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
      return path;
    }
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _WeightGainSparklinePainter oldDelegate) {
    return oldDelegate.chart != chart ||
        oldDelegate.weightColor != weightColor ||
        oldDelegate.dryColor != dryColor;
  }
}
