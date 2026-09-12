import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A draggable circular compass dial.
///
/// The user can rotate the dial by panning anywhere inside it.
/// [onHeadingChanged] is called with the new heading (0–360°) as the user drags.
class DialWidget extends StatefulWidget {
  final double heading;
  final ValueChanged<double> onHeadingChanged;

  const DialWidget({
    super.key,
    required this.heading,
    required this.onHeadingChanged,
  });

  @override
  State<DialWidget> createState() => _DialWidgetState();
}

class _DialWidgetState extends State<DialWidget> {
  // Track the angle at the start of a drag so we compute delta rotation.
  double? _lastAngle;

  double _angleFromCenter(Offset center, Offset point) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return math.atan2(dx, -dy); // angle from top (North), clockwise
  }

  void _onPanStart(DragStartDetails details, Offset center) {
    _lastAngle = _angleFromCenter(center, details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details, Offset center) {
    if (_lastAngle == null) return;
    final currentAngle = _angleFromCenter(center, details.localPosition);
    final delta = currentAngle - _lastAngle!;
    _lastAngle = currentAngle;

    final newHeading =
        ((widget.heading + _toDeg(delta)) % 360 + 360) % 360;
    widget.onHeadingChanged(newHeading);
  }

  void _onPanEnd(DragEndDetails _) {
    _lastAngle = null;
  }

  double _toDeg(double rad) => rad * 180 / math.pi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size / 2, size / 2);

        return GestureDetector(
          onPanStart: (d) => _onPanStart(d, center),
          onPanUpdate: (d) => _onPanUpdate(d, center),
          onPanEnd: _onPanEnd,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _DialPainter(heading: widget.heading),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _DialPainter extends CustomPainter {
  final double heading;

  const _DialPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ── Outer ring ──────────────────────────────────────────────────────────
    final ringPaint = Paint()
      ..color = const Color(0xFF3A2A0A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ringPaint);

    final ringBorderPaint = Paint()
      ..color = const Color(0xFF7A5520)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 1, ringBorderPaint);

    // ── Inner face ──────────────────────────────────────────────────────────
    final facePaint = Paint()
      ..color = const Color(0xFF1A1208)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.92, facePaint);

    // ── Degree markings (rotated with heading) ───────────────────────────────
    // We rotate the canvas so that 'heading' degrees points to the top.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-_toRad(heading));
    canvas.translate(-center.dx, -center.dy);

    _drawMarkings(canvas, center, radius);

    canvas.restore();

    // ── Fixed north pointer / heading arrow at top ───────────────────────────
    _drawHeadingPointer(canvas, center, radius);

    // ── Centre dot ──────────────────────────────────────────────────────────
    final dotPaint = Paint()
      ..color = const Color(0xFFD4A017)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);
  }

  void _drawMarkings(Canvas canvas, Offset center, double radius) {
    final innerMarkRadius = radius * 0.92;

    final shortTickPaint = Paint()
      ..color = const Color(0xFF7A5520)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final longTickPaint = Paint()
      ..color = const Color(0xFFD4A017)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw a tick every 5° and label every 10°
    for (int deg = 0; deg < 360; deg += 5) {
      final rad = _toRad(deg.toDouble());
      final isMajor = deg % 10 == 0;
      final tickLength = isMajor ? radius * 0.10 : radius * 0.05;
      final paint = isMajor ? longTickPaint : shortTickPaint;

      final outerX = center.dx + innerMarkRadius * math.sin(rad);
      final outerY = center.dy - innerMarkRadius * math.cos(rad);
      final innerX = center.dx + (innerMarkRadius - tickLength) * math.sin(rad);
      final innerY = center.dy - (innerMarkRadius - tickLength) * math.cos(rad);

      canvas.drawLine(Offset(outerX, outerY), Offset(innerX, innerY), paint);

      // Degree labels every 30°
      if (deg % 30 == 0) {
        _drawDegreeLabel(canvas, center, innerMarkRadius * 0.76, deg);
      }
    }

    // Cardinal / intercardinal labels
    _drawCardinalLabel(canvas, center, innerMarkRadius * 0.62, 0, 'N');
    _drawCardinalLabel(canvas, center, innerMarkRadius * 0.62, 45, 'NE');
    _drawCardinalLabel(canvas, center, innerMarkRadius * 0.62, 90, 'E');
    _drawCardinalLabel(canvas, center, innerMarkRadius * 0.62, 135, 'SE');
    _drawCardinalLabel(canvas, center, innerMarkRadius * 0.62, 180, 'S');
    _drawCardinalLabel(canvas, center, innerMarkRadius * 0.62, 225, 'SW');
    _drawCardinalLabel(canvas, center, innerMarkRadius * 0.62, 270, 'W');
    _drawCardinalLabel(canvas, center, innerMarkRadius * 0.62, 315, 'NW');
  }

  void _drawDegreeLabel(
    Canvas canvas,
    Offset center,
    double r,
    int deg,
  ) {
    // Skip degrees that will be overwritten by cardinal labels
    if (deg % 45 == 0) return;

    final rad = _toRad(deg.toDouble());
    final x = center.dx + r * math.sin(rad);
    final y = center.dy - r * math.cos(rad);

    final tp = TextPainter(
      text: TextSpan(
        text: deg.toString(),
        style: const TextStyle(
          color: Color(0xFF9E7E3A),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(_toRad(deg.toDouble())); // keep label upright relative to dial
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _drawCardinalLabel(
    Canvas canvas,
    Offset center,
    double r,
    int deg,
    String label,
  ) {
    final rad = _toRad(deg.toDouble());
    final x = center.dx + r * math.sin(rad);
    final y = center.dy - r * math.cos(rad);

    final isNorth = label == 'N';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isNorth ? const Color(0xFFFF4444) : const Color(0xFFD4A017),
          fontSize: label.length == 1 ? 13 : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(_toRad(deg.toDouble()));
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  /// Draws a fixed amber triangle pointer at the top of the dial (12 o'clock).
  void _drawHeadingPointer(Canvas canvas, Offset center, double radius) {
    final tipY = center.dy - radius * 0.94;
    final baseY = center.dy - radius * 0.78;
    final halfBase = radius * 0.04;

    final path = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - halfBase, baseY)
      ..lineTo(center.dx + halfBase, baseY)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFD4A017),
    );

    // Outer ring highlight at pointer
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.97),
      -math.pi / 2 - 0.06,
      0.12,
      false,
      Paint()
        ..color = const Color(0xFFD4A017)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.heading != heading;

  double _toRad(double deg) => deg * math.pi / 180;
}
