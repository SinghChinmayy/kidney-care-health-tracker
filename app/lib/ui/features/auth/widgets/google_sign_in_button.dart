import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Outlined "Continue with Google" control for login / signup screens.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: AppTheme.secondaryButtonStyle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _GoogleMark(size: 20),
          const SizedBox(width: AppTheme.spacingXs),
          Text(label),
        ],
      ),
    );
  }
}

/// Compact multicolor Google "G" mark (no asset dependency).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final radius = (size.width - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    paint.color = _blue;
    canvas.drawArc(rect, -0.55, 1.6, false, paint);
    paint.color = _green;
    canvas.drawArc(rect, 1.05, 1.2, false, paint);
    paint.color = _yellow;
    canvas.drawArc(rect, 2.25, 0.9, false, paint);
    paint.color = _red;
    canvas.drawArc(rect, -2.35, 1.2, false, paint);

    final barTop = center.dy - stroke / 2;
    canvas.drawRect(
      Rect.fromLTWH(center.dx, barTop, radius + stroke * 0.15, stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
