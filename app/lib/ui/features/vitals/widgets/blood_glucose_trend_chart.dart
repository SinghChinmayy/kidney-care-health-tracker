import 'dart:math' as math;

import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/models/blood_glucose_period.dart';
import 'package:flutter/material.dart';

class BloodGlucoseTrendChart extends StatefulWidget {
  const BloodGlucoseTrendChart({
    super.key,
    required this.days,
  });

  final List<BloodGlucoseChartDay> days;

  @override
  State<BloodGlucoseTrendChart> createState() => _BloodGlucoseTrendChartState();
}

class _BloodGlucoseTrendChartState extends State<BloodGlucoseTrendChart> {
  static const double _minBarSlot = 36;

  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant BloodGlucoseTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days.length != widget.days.length ||
        oldWidget.days != widget.days) {
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
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final max = _scrollController.position.maxScrollExtent;
      if (max > 0) {
        _scrollController.jumpTo(max);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    if (days.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No glucose data yet',
            style: TextStyle(color: AppTheme.muted),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.max(
          constraints.maxWidth,
          days.length * _minBarSlot,
        );
        final chart = SizedBox(
          width: contentWidth,
          height: 200,
          child: CustomPaint(
            painter: _BloodGlucoseBarChartPainter(days: days),
            child: const SizedBox.expand(),
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
    );
  }
}

class _BloodGlucoseBarChartPainter extends CustomPainter {
  _BloodGlucoseBarChartPainter({required this.days});

  final List<BloodGlucoseChartDay> days;

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 22.0;
    const bottomPad = 28.0;
    const rightPad = 40.0;
    const leftPad = 8.0;

    final plotWidth = size.width - leftPad - rightPad;
    final plotBottom = size.height - bottomPad;
    final plotHeight = plotBottom - topPad;

    final values = [
      for (final day in days)
        if (day.valueMgDl != null) day.valueMgDl!,
    ];

    var minV = 0.0;
    var maxV = values.isEmpty ? 1.0 : values.reduce(math.max);
    maxV = (maxV * 1.15).ceilToDouble();
    if (maxV <= minV) {
      maxV = minV + 1;
    }

    final gridPaint = Paint()
      ..color = AppTheme.muted.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: AppTheme.muted.withValues(alpha: 0.85),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final t = i / gridLines;
      final y = plotBottom - plotHeight * t;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );
      final value = minV + (maxV - minV) * t;
      final label = value.toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(size.width - rightPad + 6, y - tp.height / 2),
      );
    }

    final slot = plotWidth / days.length;
    final barWidth = math.min(22.0, math.max(6.0, slot * 0.55));
    final barPaint = Paint()..color = AppTheme.ink;

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final cx = leftPad + slot * (i + 0.5);

      final dayTp = TextPainter(
        text: TextSpan(text: day.axisLabel, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      dayTp.paint(
        canvas,
        Offset(cx - dayTp.width / 2, plotBottom + 8),
      );

      final value = day.valueMgDl;
      if (value == null) {
        continue;
      }

      final t = ((value - minV) / (maxV - minV)).clamp(0.0, 1.0);
      final barTop = plotBottom - plotHeight * t;
      final barHeight = math.max(4.0, plotBottom - barTop);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - barWidth / 2, barTop, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, barPaint);

      final valueTp = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: labelStyle.copyWith(fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valueTp.paint(
        canvas,
        Offset(cx - valueTp.width / 2, barTop - valueTp.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BloodGlucoseBarChartPainter oldDelegate) {
    if (oldDelegate.days.length != days.length) {
      return true;
    }
    for (var i = 0; i < days.length; i++) {
      final a = oldDelegate.days[i];
      final b = days[i];
      if (a.day != b.day ||
          a.valueMgDl != b.valueMgDl ||
          a.axisLabel != b.axisLabel) {
        return true;
      }
    }
    return false;
  }
}
