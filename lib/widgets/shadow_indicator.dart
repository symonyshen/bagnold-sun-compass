import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Draws a compass face overlay with a bold shadow-alignment line.
///
/// [shadowAngle] is degrees clockwise from North (0 = shadow points North).
/// The line represents where the user should align the shadow cast by a
/// vertical object on the phone screen.
class ShadowIndicator extends StatelessWidget {
  final double shadowAngle;
  final double sunAltitude;

  const ShadowIndicator({
    super.key,
    required this.shadowAngle,
    required this.sunAltitude,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ShadowPainter(
              shadowAngle: shadowAngle,
              sunBelowHorizon: sunAltitude <= 0,
            ),
          ),
        );
      },
    );
  }
}

class _ShadowPainter extends CustomPainter {
  final double shadowAngle;
  final bool sunBelowHorizon;

  const _ShadowPainter({
    required this.shadowAngle,
    required this.sunBelowHorizon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (sunBelowHorizon) {
      _drawBelowHorizonOverlay(canvas, center, radius);
      return;
    }

    // ── Subtle background circle ────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius * 0.98,
      Paint()
        ..color = const Color(0x22D4A017)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Shadow line ─────────────────────────────────────────────────────────
    final rad = _toRad(shadowAngle);
    final lineEnd = Offset(
      center.dx + radius * 0.88 * math.sin(rad),
      center.dy - radius * 0.88 * math.cos(rad),
    );
    final lineStart = Offset(
      center.dx - radius * 0.30 * math.sin(rad),
      center.dy + radius * 0.30 * math.cos(rad),
    );

    // Glow effect — draw a wide translucent line first
    canvas.drawLine(
      lineStart,
      lineEnd,
      Paint()
        ..color = const Color(0x55FFDD44)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    // Dashed core line
    _drawDashedLine(canvas, lineStart, lineEnd,
        dashLength: 12, gapLength: 6,
        paint: Paint()
          ..color = const Color(0xFFFFDD44)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);

    // Arrowhead at the far end
    _drawArrowhead(canvas, lineStart, lineEnd, radius * 0.06);

    // ── "align shadow here" label ────────────────────────────────────────────
    _drawLabel(canvas, center, radius, shadowAngle);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end, {
    required double dashLength,
    required double gapLength,
    required Paint paint,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalLen = math.sqrt(dx * dx + dy * dy);
    final nx = dx / totalLen;
    final ny = dy / totalLen;

    double drawn = 0;
    bool drawing = true;
    while (drawn < totalLen) {
      final segLen =
          drawing ? dashLength : gapLength;
      final next = math.min(drawn + segLen, totalLen);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + nx * drawn, start.dy + ny * drawn),
          Offset(start.dx + nx * next, start.dy + ny * next),
          paint,
        );
      }
      drawn = next;
      drawing = !drawing;
    }
  }

  void _drawArrowhead(
      Canvas canvas, Offset from, Offset to, double size) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final angle = math.atan2(dy, dx);

    final path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(
      to.dx - size * math.cos(angle - math.pi / 6),
      to.dy - size * math.sin(angle - math.pi / 6),
    );
    path.lineTo(
      to.dx - size * math.cos(angle + math.pi / 6),
      to.dy - size * math.sin(angle + math.pi / 6),
    );
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFDD44)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawLabel(
      Canvas canvas, Offset center, double radius, double shadowAngle) {
    // Place label on the far side of the line (slightly rotated)
    const labelRadius = 0.55;
    final labelRad = _toRad(shadowAngle);
    final labelX = center.dx + radius * labelRadius * math.sin(labelRad);
    final labelY = center.dy - radius * labelRadius * math.cos(labelRad);

    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 9,
    ))
      ..pushStyle(ui.TextStyle(
        color: const Color(0xFFFFDD44),
        fontSize: 9,
        fontWeight: ui.FontWeight.w600,
        letterSpacing: 0.5,
      ))
      ..addText('align\nshadow\nhere');

    final para = pb.build()
      ..layout(const ui.ParagraphConstraints(width: 60));

    canvas.save();
    canvas.translate(labelX, labelY);
    canvas.rotate(_toRad(shadowAngle));
    canvas.drawParagraph(para, Offset(-30, -para.height / 2));
    canvas.restore();
  }

  void _drawBelowHorizonOverlay(
      Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius * 0.98,
      Paint()
        ..color = const Color(0x44FF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'Sun below horizon\nNavigation unavailable',
        style: TextStyle(
          color: Color(0xAAFF6666),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.6,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: radius * 1.4);

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ShadowPainter old) =>
      old.shadowAngle != shadowAngle || old.sunBelowHorizon != sunBelowHorizon;

  double _toRad(double deg) => deg * math.pi / 180;
}
