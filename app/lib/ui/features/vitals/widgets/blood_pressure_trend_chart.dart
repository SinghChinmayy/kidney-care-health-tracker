import 'dart:math' as math;
import 'dart:ui';

import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/models/blood_pressure_period.dart';
import 'package:flutter/material.dart';

const _systolicColor = Color(0xFFE57373);
const _diastolicColor = Color(0xFF4DB6AC);

class BloodPressureTrendChart extends StatefulWidget {
  const BloodPressureTrendChart({
    super.key,
    required this.days,
    this.compact = false,
  });

  final List<BloodPressureChartDay> days;
  final bool compact;

  @override
  State<BloodPressureTrendChart> createState() =>
      _BloodPressureTrendChartState();
}

class _BloodPressureTrendChartState extends State<BloodPressureTrendChart> {
  static const double _minSlot = 36;
  static const double _chartHeight = 210;
  static const double _compactChartHeight = 132;

  final _scrollController = ScrollController();
  double? _touchX; // null = no touch active

  @override
  void didUpdateWidget(covariant BloodPressureTrendChart oldWidget) {
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
            'No blood pressure data yet',
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
              _LegendDot(
                color: _systolicColor,
                label: 'Systolic',
                compact: compact,
              ),
              SizedBox(width: compact ? 10 : 16),
              _LegendDot(
                color: _diastolicColor,
                label: 'Diastolic',
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

            final painter = _BpLineChartPainter(
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
                onHorizontalDragEnd: (_) =>
                    setState(() => _touchX = null),
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
  const _LegendDot({
    required this.color,
    required this.label,
    this.compact = false,
  });
  final Color color;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 8 : 10,
          height: compact ? 8 : 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _BpLineChartPainter extends CustomPainter {
  _BpLineChartPainter({
    required this.days,
    this.touchX,
    this.compact = false,
  });

  final List<BloodPressureChartDay> days;
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

    // ---- Value range ----
    final allValues = <double>[
      for (final d in days) ...[
        if (d.systolic != null) d.systolic!.toDouble(),
        if (d.diastolic != null) d.diastolic!.toDouble(),
      ],
    ];
    if (allValues.isEmpty) return;

    final rawMin = allValues.reduce(math.min);
    final rawMax = allValues.reduce(math.max);
    final padding = math.max(10.0, (rawMax - rawMin) * 0.15);
    final minV = math.max(0.0, rawMin - padding);
    final maxV = rawMax + padding;

    double toY(double v) =>
        plotBottom - plotHeight * ((v - minV) / (maxV - minV)).clamp(0.0, 1.0);

    final slot = plotWidth / days.length;

    double cx(int i) => plotLeft + slot * (i + 0.5);

    // ---- Grid lines ----
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

    // ---- X-axis labels ----
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      _paintText(
        canvas,
        day.axisLabel,
        labelStyle,
        Offset(cx(i) - 4, plotBottom + 6),
      );
    }

    // ---- Lines ----
    _drawLine(canvas, days, slot, plotLeft, toY, (d) => d.systolic?.toDouble(),
        _systolicColor);
    _drawLine(canvas, days, slot, plotLeft, toY,
        (d) => d.diastolic?.toDouble(), _diastolicColor);

    // ---- Touch indicator ----
    final tx = touchX;
    if (tx != null && tx >= plotLeft && tx <= plotRight) {
      final idx = ((tx - plotLeft) / slot).floor().clamp(0, days.length - 1);
      final snapX = cx(idx);
      final day = days[idx];

      // vertical line
      final cursorPaint = Paint()
        ..color = AppTheme.muted.withValues(alpha: 0.35)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(snapX, plotTop),
        Offset(snapX, plotBottom),
        cursorPaint,
      );

      // dots on each line
      if (day.systolic != null) {
        _drawDot(canvas, snapX, toY(day.systolic!.toDouble()), _systolicColor);
      }
      if (day.diastolic != null) {
        _drawDot(
            canvas, snapX, toY(day.diastolic!.toDouble()), _diastolicColor);
      }

      // tooltip bubble
      _drawTooltip(canvas, size, snapX, plotTop, day, labelStyle);
    }
  }

  void _drawLine(
    Canvas canvas,
    List<BloodPressureChartDay> days,
    double slot,
    double plotLeft,
    double Function(double) toY,
    double? Function(BloodPressureChartDay) getValue,
    Color color,
  ) {
    // Collect segments of consecutive non-null points
    final segments = <List<Offset>>[];
    List<Offset>? current;

    for (var i = 0; i < days.length; i++) {
      final v = getValue(days[i]);
      final x = plotLeft + slot * (i + 0.5);
      if (v != null) {
        current ??= [];
        current.add(Offset(x, toY(v)));
      } else {
        if (current != null && current.length >= 1) {
          segments.add(current);
        }
        current = null;
      }
    }
    if (current != null && current.isNotEmpty) segments.add(current);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final seg in segments) {
      if (seg.length == 1) {
        canvas.drawCircle(seg.first, 3, Paint()..color = color);
        continue;
      }
      final path = Path();
      path.moveTo(seg.first.dx, seg.first.dy);
      for (var i = 1; i < seg.length; i++) {
        final prev = seg[i - 1];
        final curr = seg[i];
        final cpX = (prev.dx + curr.dx) / 2;
        path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  void _drawDot(Canvas canvas, double x, double y, Color color) {
    canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(x, y),
      5,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawTooltip(
    Canvas canvas,
    Size size,
    double x,
    double plotTop,
    BloodPressureChartDay day,
    TextStyle baseStyle,
  ) {
    final lines = <String>[];
    if (day.systolic != null) lines.add('Sys: ${day.systolic}');
    if (day.diastolic != null) lines.add('Dia: ${day.diastolic}');
    if (lines.isEmpty) return;

    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    const lineSpacing = 14.0;
    const fontSize = 11.0;

    final tooltipStyle = baseStyle.copyWith(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );

    // Measure text
    double maxW = 0;
    final painters = <TextPainter>[];
    for (final line in lines) {
      final tp = TextPainter(
        text: TextSpan(text: line, style: tooltipStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painters.add(tp);
      if (tp.width > maxW) maxW = tp.width;
    }

    final boxW = maxW + padding.horizontal;
    final boxH = lines.length * lineSpacing + padding.vertical;

    var bx = x - boxW / 2;
    bx = bx.clamp(4.0, size.width - _rightPad - boxW - 4);
    final by = plotTop - boxH - 6;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bx, by, boxW, boxH),
      const Radius.circular(8),
    );

    final bgPaint = Paint()
      ..color = const Color(0xFF1C1C1E)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, bgPaint);

    final solidPaint = Paint()..color = const Color(0xFF1C1C1E);
    canvas.drawRRect(rrect, solidPaint);

    var ty = by + padding.top;
    for (final tp in painters) {
      tp.paint(canvas, Offset(bx + padding.left, ty));
      ty += lineSpacing;
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
  bool shouldRepaint(covariant _BpLineChartPainter old) {
    if (old.touchX != touchX) return true;
    if (old.compact != compact) return true;
    if (old.days.length != days.length) return true;
    for (var i = 0; i < days.length; i++) {
      final a = old.days[i];
      final b = days[i];
      if (a.day != b.day ||
          a.systolic != b.systolic ||
          a.diastolic != b.diastolic) return true;
    }
    return false;
  }
}
