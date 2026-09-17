import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small, static, non-interactive compass rose used as a fixed
/// orientation reference on the path canvas (which is drawn north-up).
class CompassRose extends StatelessWidget {
  final double size;

  const CompassRose({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CompassRosePainter()),
    );
  }
}

class _CompassRosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xCC2A1F0E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF7A5520)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1, borderPaint);

    _drawTick(canvas, center, radius, 0, const Color(0xFFFF4444), 'N');
    _drawTick(canvas, center, radius, 90, const Color(0xFFD4A017), 'E');
    _drawTick(canvas, center, radius, 180, const Color(0xFFD4A017), 'S');
    _drawTick(canvas, center, radius, 270, const Color(0xFFD4A017), 'W');

    // North arrow.
    final tipY = center.dy - radius * 0.6;
    final baseY = center.dy - radius * 0.15;
    final halfBase = radius * 0.14;
    final path = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - halfBase, baseY)
      ..lineTo(center.dx + halfBase, baseY)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFF4444));

    canvas.drawCircle(center, 2, Paint()..color = const Color(0xFFD4A017));
  }

  void _drawTick(Canvas canvas, Offset center, double radius, double deg,
      Color color, String label) {
    final rad = deg * math.pi / 180.0;
    final labelRadius = radius * 0.72;
    final x = center.dx + labelRadius * math.sin(rad);
    final y = center.dy - labelRadius * math.cos(rad);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(_CompassRosePainter oldDelegate) => false;
}
