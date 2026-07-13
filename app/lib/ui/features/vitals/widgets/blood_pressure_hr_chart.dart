import 'dart:math' as math;

import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/models/blood_pressure_period.dart';
import 'package:flutter/material.dart';

const _hrLineColor = Color(0xFF8BC34A);

class BloodPressureHrChart extends StatefulWidget {
  const BloodPressureHrChart({
    super.key,
    required this.days,
    this.compact = false,
    this.avgHr,
  });

  final List<BloodPressureChartDay> days;
  final bool compact;
  final double? avgHr;

  @override
  State<BloodPressureHrChart> createState() => _BloodPressureHrChartState();
}

class _BloodPressureHrChartState extends State<BloodPressureHrChart> {
  static const double _minSlot = 36;
  static const double _chartHeight = 140;
  static const double _compactChartHeight = 112;

  final _scrollController = ScrollController();
  double? _touchX;

  @override
  void didUpdateWidget(covariant BloodPressureHrChart oldWidget) {
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
    final theme = Theme.of(context);
    final days = widget.days;
    final compact = widget.compact;
    final chartHeight = compact ? _compactChartHeight : _chartHeight;

    final hasHrData = days.any((d) => d.heartRateBpm != null);
    if (!hasHrData) {
      return SizedBox(
        height: compact ? 100 : 120,
        child: const Center(
          child: Text(
            'No heart rate data yet',
            style: TextStyle(color: AppTheme.muted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: _hrLineColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Heart Rate',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        if (!compact) const SizedBox(height: 8),
        if (compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _hrLineColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Heart rate',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
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
                  painter: _HrLinePainter(
                    days: days,
                    touchX: _touchX,
                    compact: compact,
                  ),
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
        if (compact && widget.avgHr != null) ...[
          const SizedBox(height: 4),
          Text(
            'Avg ${widget.avgHr!.round()} bpm',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _HrLinePainter extends CustomPainter {
  _HrLinePainter({
    required this.days,
    this.touchX,
    this.compact = false,
  });

  final List<BloodPressureChartDay> days;
  final double? touchX;
  final bool compact;

  double get _topPad => compact ? 14.0 : 20.0;
  double get _bottomPad => compact ? 16.0 : 22.0;
  double get _leftPad => compact ? 4.0 : 6.0;
  double get _rightPad => compact ? 30.0 : 38.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plotLeft = _leftPad;
    final plotRight = size.width - _rightPad;
    final plotWidth = plotRight - plotLeft;
    final plotBottom = size.height - _bottomPad;
    final plotTop = _topPad;
    final plotHeight = plotBottom - plotTop;

    final hrValues = [
      for (final d in days)
        if (d.heartRateBpm != null) d.heartRateBpm!.toDouble(),
    ];
    if (hrValues.isEmpty) return;

    final rawMin = hrValues.reduce(math.min);
    final rawMax = hrValues.reduce(math.max);
    final padding = math.max(8.0, (rawMax - rawMin) * 0.15);
    final minV = math.max(0.0, rawMin - padding);
    final maxV = rawMax + padding;

    double toY(double v) =>
        plotBottom - plotHeight * ((v - minV) / (maxV - minV)).clamp(0.0, 1.0);

    final slot = plotWidth / days.length;
    double cx(int i) => plotLeft + slot * (i + 0.5);

    final labelStyle = TextStyle(
      color: AppTheme.muted.withValues(alpha: 0.75),
      fontSize: compact ? 9 : 10,
      fontWeight: FontWeight.w500,
    );

    final gridPaint = Paint()
      ..color = AppTheme.muted.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final gridLines = compact ? 2 : 3;
    for (var i = 0; i <= gridLines; i++) {
      final t = i / gridLines;
      final v = minV + (maxV - minV) * t;
      final y = toY(v);
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
      _paintText(
        canvas,
        v.toStringAsFixed(0),
        labelStyle,
        Offset(plotRight + 4, y - 6),
      );
    }

    for (var i = 0; i < days.length; i++) {
      _paintText(
        canvas,
        days[i].axisLabel,
        labelStyle,
        Offset(cx(i) - 4, plotBottom + 4),
      );
    }

    final points = <Offset>[];
    for (var i = 0; i < days.length; i++) {
      final hr = days[i].heartRateBpm;
      if (hr != null) points.add(Offset(cx(i), toY(hr.toDouble())));
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
          ..color = _hrLineColor.withValues(alpha: 0.12)
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
          ..color = _hrLineColor
          ..strokeWidth = compact ? 1.8 : 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else if (points.length == 1) {
      canvas.drawCircle(points.first, 3, Paint()..color = _hrLineColor);
    }

    final tx = touchX;
    if (tx != null && tx >= plotLeft && tx <= plotRight) {
      final idx = ((tx - plotLeft) / slot).floor().clamp(0, days.length - 1);
      final snapX = cx(idx);
      final day = days[idx];

      final cursorPaint = Paint()
        ..color = AppTheme.muted.withValues(alpha: 0.3)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(snapX, plotTop),
        Offset(snapX, plotBottom),
        cursorPaint,
      );

      final hr = day.heartRateBpm;
      if (hr != null) {
        final dotY = toY(hr.toDouble());
        canvas.drawCircle(Offset(snapX, dotY), 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          Offset(snapX, dotY),
          5,
          Paint()
            ..color = _hrLineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );

        final label = '$hr BPM';
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
        const vPad = 5.0;
        final boxW = tp.width + hPad * 2;
        final boxH = tp.height + vPad * 2;
        var bx = snapX - boxW / 2;
        bx = bx.clamp(4.0, size.width - _rightPad - boxW - 4);
        final by = plotTop - boxH - 4;
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
  bool shouldRepaint(covariant _HrLinePainter old) {
    if (old.touchX != touchX) return true;
    if (old.compact != compact) return true;
    if (old.days.length != days.length) return true;
    for (var i = 0; i < days.length; i++) {
      if (old.days[i].heartRateBpm != days[i].heartRateBpm) return true;
    }
    return false;
  }
}
