import 'dart:math' as math;

import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/models/fluid_intake_period.dart';
import 'package:flutter/material.dart';

const _fluidLineColor = AppTheme.logFluidIntake;

class FluidIntakeTrendChart extends StatefulWidget {
  const FluidIntakeTrendChart({
    super.key,
    required this.days,
    this.compact = false,
  });

  final List<FluidIntakeChartDay> days;
  final bool compact;

  @override
  State<FluidIntakeTrendChart> createState() => _FluidIntakeTrendChartState();
}

class _FluidIntakeTrendChartState extends State<FluidIntakeTrendChart> {
  static const double _minSlot = 36;
  static const double _chartHeight = 210;
  static const double _compactChartHeight = 132;

  final _scrollController = ScrollController();
  double? _touchX;

  @override
  void didUpdateWidget(covariant FluidIntakeTrendChart oldWidget) {
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
            'No water data yet',
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
              _LegendDot(compact: compact),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = math.max(
              constraints.maxWidth,
              days.length * _minSlot,
            );

            final painter = _FluidLineChartPainter(
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 8 : 10,
          height: compact ? 8 : 10,
          decoration: const BoxDecoration(
            color: _fluidLineColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: compact ? 4 : 5),
        Text(
          'Daily total',
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

class _FluidLineChartPainter extends CustomPainter {
  _FluidLineChartPainter({
    required this.days,
    this.touchX,
    this.compact = false,
  });

  final List<FluidIntakeChartDay> days;
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

    final values = [
      for (final d in days)
        if (d.totalMl != null) d.totalMl!,
    ];
    if (values.isEmpty) return;

    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final padding = math.max(50.0, (rawMax - rawMin) * 0.15);
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
        v.toStringAsFixed(0),
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

    final points = <Offset>[];
    for (var i = 0; i < days.length; i++) {
      final value = days[i].totalMl;
      if (value != null) {
        points.add(Offset(cx(i), toY(value)));
      }
    }

    if (points.length >= 2) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, plotBottom);
      fillPath.lineTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final cpX = (prev.dx + curr.dx) / 2;
        fillPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
      fillPath.lineTo(points.last.dx, plotBottom);
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..color = _fluidLineColor.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );

      final strokePath = Path();
      strokePath.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final cpX = (prev.dx + curr.dx) / 2;
        strokePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
      canvas.drawPath(
        strokePath,
        Paint()
          ..color = _fluidLineColor
          ..strokeWidth = compact ? 2.0 : 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else if (points.length == 1) {
      canvas.drawCircle(points.first, 3, Paint()..color = _fluidLineColor);
    }

    final tx = touchX;
    if (tx != null && tx >= plotLeft && tx <= plotRight) {
      final idx = ((tx - plotLeft) / slot).floor().clamp(0, days.length - 1);
      final snapX = cx(idx);
      final day = days[idx];
      final value = day.totalMl;

      final cursorPaint = Paint()
        ..color = AppTheme.muted.withValues(alpha: 0.35)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(snapX, plotTop),
        Offset(snapX, plotBottom),
        cursorPaint,
      );

      if (value != null) {
        final dotY = toY(value);
        canvas.drawCircle(Offset(snapX, dotY), 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          Offset(snapX, dotY),
          5,
          Paint()
            ..color = _fluidLineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );

        final label = '${value.toStringAsFixed(0)} ml';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
  }

  void _paintText(Canvas canvas, String text, TextStyle style, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _FluidLineChartPainter old) {
    if (old.touchX != touchX) return true;
    if (old.compact != compact) return true;
    if (old.days.length != days.length) return true;
    for (var i = 0; i < days.length; i++) {
      final a = old.days[i];
      final b = days[i];
      if (a.day != b.day ||
          a.totalMl != b.totalMl ||
          a.axisLabel != b.axisLabel) {
        return true;
      }
    }
    return false;
  }
}
