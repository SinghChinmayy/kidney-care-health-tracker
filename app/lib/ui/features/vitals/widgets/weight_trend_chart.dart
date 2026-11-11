import 'dart:math' as math;

import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/models/weight_period.dart';
import 'package:flutter/material.dart';

const _weightLineColor = AppTheme.logWeight;
const _dryLineColor = Color(0xFF4DB6AC);

class WeightTrendChart extends StatefulWidget {
  const WeightTrendChart({
    super.key,
    required this.days,
    this.compact = false,
  });

  final List<WeightChartDay> days;
  final bool compact;

  @override
  State<WeightTrendChart> createState() => _WeightTrendChartState();
}

class _WeightTrendChartState extends State<WeightTrendChart> {
  static const double _minSlot = 36;
  static const double _chartHeight = 210;
  static const double _compactChartHeight = 132;

  final _scrollController = ScrollController();
  double? _touchX;

  @override
  void didUpdateWidget(covariant WeightTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days.length != widget.days.length ||
        oldWidget.days != widget.days) {
      _touchX = null;
      _scrollToLatest();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max > 0) _scrollController.jumpTo(max);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    final compact = widget.compact;
    final chartHeight = compact ? _compactChartHeight : _chartHeight;
    if (days.isEmpty) {
      return SizedBox(
        height: compact ? 100 : 180,
        child: const Center(
          child: Text(
            'No weight data yet',
            style: TextStyle(color: AppTheme.muted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: compact ? 4 : 8),
          child: Row(
            children: [
              _LegendItem(
                color: _dryLineColor,
                label: 'Dry weight',
                dashed: true,
                compact: compact,
              ),
              SizedBox(width: compact ? 12 : 16),
              _LegendItem(
                color: _weightLineColor,
                label: 'Weight',
                compact: compact,
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = math.max(
              constraints.maxWidth,
              days.length * _minSlot,
            );

            final painter = _WeightLineChartPainter(
              days: days,
              touchX: _touchX,
              compact: compact,
            );

            Widget chart = SizedBox(
              width: contentWidth,
              height: chartHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) {
                  final rx = d.localPosition.dx;
                  if (rx >= 0 && rx <= contentWidth) {
                    setState(() => _touchX = rx);
                  }
                },
                onHorizontalDragEnd: (_) => setState(() => _touchX = null),
                onTapDown: (d) =>
                    setState(() => _touchX = d.localPosition.dx),
                onTapUp: (_) => setState(() => _touchX = null),
                child: CustomPaint(
                  painter: painter,
                  child: const SizedBox.expand(),
                ),
              ),
            );

            if (contentWidth <= constraints.maxWidth + 0.5) {
              return chart;
            }
            _scrollToLatest();
            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: chart,
            );
          },
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
    this.compact = false,
  });

  final Color color;
  final String label;
  final bool dashed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          CustomPaint(
            size: Size(compact ? 14 : 16, compact ? 8 : 10),
            painter: _DashedLegendPainter(color: color),
          )
        else
          Container(
            width: compact ? 8 : 10,
            height: compact ? 8 : 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        SizedBox(width: compact ? 4 : 5),
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}

class _DashedLegendPainter extends CustomPainter {
  _DashedLegendPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const dash = 3.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
      x += dash * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLegendPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _WeightLineChartPainter extends CustomPainter {
  _WeightLineChartPainter({
    required this.days,
    this.touchX,
    this.compact = false,
  });

  final List<WeightChartDay> days;
  final double? touchX;
  final bool compact;

  double get _topPad => compact ? 18.0 : 28.0;
  double get _bottomPad => compact ? 20.0 : 28.0;
  double get _leftPad => compact ? 4.0 : 8.0;
  double get _rightPad => compact ? 34.0 : 44.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plotLeft = _leftPad;
    final plotRight = size.width - _rightPad;
    final plotWidth = plotRight - plotLeft;
    final plotBottom = size.height - _bottomPad;
    final plotTop = _topPad;
    final plotHeight = plotBottom - plotTop;

    final values = <double>[
      for (final d in days) ...[
        if (d.weightKg != null) d.weightKg!,
        if (d.dryWeightKg != null) d.dryWeightKg!,
      ],
    ];
    if (values.isEmpty) return;

    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final padding = math.max(0.5, (rawMax - rawMin) * 0.15);
    final minV = math.max(0.0, rawMin - padding);
    final maxV = rawMax + padding;

    double toY(double v) =>
        plotBottom - plotHeight * ((v - minV) / (maxV - minV)).clamp(0.0, 1.0);

    final slot = plotWidth / days.length;
    double cx(int i) => plotLeft + slot * (i + 0.5);

    final gridPaint = Paint()
      ..color = AppTheme.muted.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: AppTheme.muted.withValues(alpha: 0.8),
      fontSize: compact ? 9.5 : 10.5,
      fontWeight: FontWeight.w500,
    );

    final gridCount = compact ? 3 : 4;
    for (var i = 0; i <= gridCount; i++) {
      final t = i / gridCount;
      final v = minV + (maxV - minV) * t;
      final y = toY(v);
      canvas.drawLine(
        Offset(plotLeft, y),
        Offset(plotRight, y),
        gridPaint,
      );
      _paintText(
        canvas,
        v.toStringAsFixed(1),
        labelStyle,
        Offset(plotRight + 6, y - 6),
      );
    }

    for (var i = 0; i < days.length; i++) {
      _paintText(
        canvas,
        days[i].axisLabel,
        labelStyle,
        Offset(cx(i) - 4, plotBottom + 6),
      );
    }

    final weightPoints = <Offset>[];
    final dryPoints = <Offset>[];
    for (var i = 0; i < days.length; i++) {
      final weight = days[i].weightKg;
      if (weight != null) {
        weightPoints.add(Offset(cx(i), toY(weight)));
      }
      final dry = days[i].dryWeightKg;
      if (dry != null) {
        dryPoints.add(Offset(cx(i), toY(dry)));
      }
    }

    // Weight: solid + fill (primary).
    if (weightPoints.length >= 2) {
      final fillPath = Path();
      fillPath.moveTo(weightPoints.first.dx, plotBottom);
      fillPath.lineTo(weightPoints.first.dx, weightPoints.first.dy);
      for (var i = 1; i < weightPoints.length; i++) {
        final prev = weightPoints[i - 1];
        final curr = weightPoints[i];
        final cpX = (prev.dx + curr.dx) / 2;
        fillPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
      fillPath.lineTo(weightPoints.last.dx, plotBottom);
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..color = _weightLineColor.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );

      final strokePath = Path();
      strokePath.moveTo(weightPoints.first.dx, weightPoints.first.dy);
      for (var i = 1; i < weightPoints.length; i++) {
        final prev = weightPoints[i - 1];
        final curr = weightPoints[i];
        final cpX = (prev.dx + curr.dx) / 2;
        strokePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
      canvas.drawPath(
        strokePath,
        Paint()
          ..color = _weightLineColor
          ..strokeWidth = compact ? 2.0 : 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else if (weightPoints.length == 1) {
      canvas.drawCircle(
        weightPoints.first,
        3,
        Paint()..color = _weightLineColor,
      );
    }

    // Dry weight: teal dashed + dots (no fill).
    if (dryPoints.length >= 2) {
      _drawDashedCubic(
        canvas,
        dryPoints,
        Paint()
          ..color = _dryLineColor
          ..strokeWidth = compact ? 1.8 : 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (final point in dryPoints) {
      canvas.drawCircle(point, compact ? 3.0 : 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        compact ? 3.0 : 3.5,
        Paint()
          ..color = _dryLineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      canvas.drawCircle(
        point,
        compact ? 1.4 : 1.6,
        Paint()..color = _dryLineColor,
      );
    }
    if (dryPoints.length == 1) {
      // Already drawn as a dot above.
    }

    final tx = touchX;
    if (tx != null && tx >= plotLeft && tx <= plotRight) {
      final idx = ((tx - plotLeft) / slot).floor().clamp(0, days.length - 1);
      final snapX = cx(idx);
      final day = days[idx];

      final cursorPaint = Paint()
        ..color = AppTheme.muted.withValues(alpha: 0.35)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(snapX, plotTop),
        Offset(snapX, plotBottom),
        cursorPaint,
      );

      if (day.weightKg != null) {
        final dotY = toY(day.weightKg!);
        canvas.drawCircle(Offset(snapX, dotY), 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          Offset(snapX, dotY),
          5,
          Paint()
            ..color = _weightLineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (day.dryWeightKg != null) {
        final dotY = toY(day.dryWeightKg!);
        canvas.drawCircle(Offset(snapX, dotY), 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          Offset(snapX, dotY),
          5,
          Paint()
            ..color = _dryLineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      final lines = <String>[
        if (day.dryWeightKg != null)
          'Dry ${day.dryWeightKg!.toStringAsFixed(1)} kg',
        if (day.weightKg != null)
          'Weight ${day.weightKg!.toStringAsFixed(1)} kg',
      ];
      if (lines.isEmpty) return;

      final label = lines.join('\n');
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      const hPad = 10.0;
      const vPad = 6.0;
      final boxW = tp.width + hPad * 2;
      final boxH = tp.height + vPad * 2;
      var bx = snapX - boxW / 2;
      bx = bx.clamp(4.0, size.width - _rightPad - boxW - 4);
      final by = plotTop - boxH - 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, boxW, boxH),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1C1C1E));
      tp.paint(canvas, Offset(bx + hPad, by + vPad));
    }
  }

  void _drawDashedCubic(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    for (final metric in path.computeMetrics()) {
      const dashLength = 5.0;
      const gapLength = 4.0;
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  void _paintText(Canvas canvas, String text, TextStyle style, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeightLineChartPainter old) {
    if (old.touchX != touchX) return true;
    if (old.compact != compact) return true;
    if (old.days.length != days.length) return true;
    for (var i = 0; i < days.length; i++) {
      final a = old.days[i];
      final b = days[i];
      if (a.day != b.day ||
          a.weightKg != b.weightKg ||
          a.dryWeightKg != b.dryWeightKg ||
          a.axisLabel != b.axisLabel) {
        return true;
      }
    }
    return false;
  }
}
