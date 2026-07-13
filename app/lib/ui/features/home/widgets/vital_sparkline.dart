import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shared smooth sparkline widget used by all vital home cards and tiles.
///
/// Accepts pre-extracted [values] as doubles so it is completely agnostic
/// to the underlying data model.  Uses a cubic-bezier (Catmull-Rom style)
/// path for smooth curves and a gradient fill beneath the line.
class VitalSparkline extends StatelessWidget {
  const VitalSparkline({
    super.key,
    required this.values,
    required this.lineColor,
    this.onDarkBackground = false,
  });

  final List<double> values;
  final Color lineColor;

  /// When true the empty-state placeholder uses [lineColor] at low opacity
  /// (suits coloured tile backgrounds). When false it uses [AppTheme.muted].
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VitalSparklinePainter(
        values: values,
        lineColor: lineColor,
        onDarkBackground: onDarkBackground,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _VitalSparklinePainter extends CustomPainter {
  _VitalSparklinePainter({
    required this.values,
    required this.lineColor,
    required this.onDarkBackground,
  });

  final List<double> values;
  final Color lineColor;
  final bool onDarkBackground;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      final placeholderColor = onDarkBackground
          ? lineColor.withValues(alpha: 0.35)
          : AppTheme.muted.withValues(alpha: 0.2);
      canvas.drawLine(
        Offset(0, size.height * 0.55),
        Offset(size.width, size.height * 0.55),
        Paint()
          ..color = placeholderColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if ((maxV - minV).abs() < 1) {
      minV -= 10;
      maxV += 10;
    }
    final pad = (maxV - minV) * 0.2;
    minV -= pad;
    maxV += pad;

    double yFor(double v) {
      final t = ((v - minV) / (maxV - minV)).clamp(0.0, 1.0);
      return size.height * (0.90 - 0.80 * t);
    }

    final n = values.length;
    final xs = List<double>.generate(n, (i) {
      if (n == 1) return size.width * 0.5;
      return size.width * (i / (n - 1));
    });

    final offsets = [
      for (var i = 0; i < n; i++) Offset(xs[i], yFor(values[i])),
    ];

    final path = _smoothPath(offsets);

    // Gradient fill under the curve.
    final fillPath = Path.from(path)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [
            lineColor.withValues(alpha: 0.28),
            lineColor.withValues(alpha: 0.0),
          ],
        ),
    );

    // Stroke line.
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dot at the latest (right-most) data point.
    final end = offsets.last;
    canvas.drawCircle(end, 5.0, Paint()..color = lineColor.withValues(alpha: 0.25));
    canvas.drawCircle(end, 3.5, Paint()..color = lineColor);
  }

  /// Smooth Catmull-Rom-style cubic bezier through [pts].
  Path _smoothPath(List<Offset> pts) {
    if (pts.length < 2) return Path()..moveTo(pts.first.dx, pts.first.dy);
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 3, p0.dy);
      final cp2 = Offset(p1.dx - (p1.dx - p0.dx) / 3, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _VitalSparklinePainter old) =>
      old.lineColor != lineColor ||
      old.onDarkBackground != onDarkBackground ||
      old.values.length != values.length ||
      !_listEqual(old.values, values);

  static bool _listEqual(List<double> a, List<double> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
