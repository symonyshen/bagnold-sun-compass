import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/checkpoint.dart';
import 'compass_rose.dart';

/// An abstract (non-georeferenced-tile) canvas showing the checkpoint
/// history connected by a line, plus the live dead-reckoning estimate (if
/// any) as a dashed segment from the last checkpoint. A fixed compass rose
/// sits in the top-right corner for orientation — the canvas is drawn
/// north-up.
class PathCanvas extends StatelessWidget {
  final List<Checkpoint> checkpoints;
  final ({double latitude, double longitude})? liveEstimate;

  const PathCanvas({
    super.key,
    required this.checkpoints,
    this.liveEstimate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: CustomPaint(
                painter: _PathPainter(
                  checkpoints: checkpoints,
                  liveEstimate: liveEstimate,
                ),
              ),
            ),
            const Positioned(top: 12, right: 12, child: CompassRose()),
          ],
        );
      },
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Checkpoint> checkpoints;
  final ({double latitude, double longitude})? liveEstimate;

  const _PathPainter({required this.checkpoints, this.liveEstimate});

  static const double _metersPerDegreeLat = 111320.0;
  static const double _minSpanMeters = 30.0;
  static const double _padding = 32.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (checkpoints.isEmpty) return;

    final originLat = checkpoints.first.latitude;
    final originLng = checkpoints.first.longitude;
    final cosLat = math.cos(originLat * math.pi / 180.0);

    // Equirectangular approximation, local meters, north = up.
    Offset project(double lat, double lng) {
      final xMeters = (lng - originLng) * _metersPerDegreeLat * cosLat;
      final yMeters = (lat - originLat) * _metersPerDegreeLat;
      return Offset(xMeters, -yMeters);
    }

    final checkpointPoints =
        checkpoints.map((c) => project(c.latitude, c.longitude)).toList();
    final estimatePoint = liveEstimate == null
        ? null
        : project(liveEstimate!.latitude, liveEstimate!.longitude);

    final boundsPoints = [
      ...checkpointPoints,
      if (estimatePoint != null) estimatePoint,
    ];

    double minX = boundsPoints.first.dx, maxX = boundsPoints.first.dx;
    double minY = boundsPoints.first.dy, maxY = boundsPoints.first.dy;
    for (final p in boundsPoints) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    final spanX = math.max(maxX - minX, _minSpanMeters);
    final spanY = math.max(maxY - minY, _minSpanMeters);
    final availableW = math.max(size.width - _padding * 2, 1.0);
    final availableH = math.max(size.height - _padding * 2, 1.0);

    // Single isotropic scale so on-screen bearings match the compass rose.
    final scale = math.min(availableW / spanX, availableH / spanY);

    final centerMeters = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    final centerScreen = Offset(size.width / 2, size.height / 2);

    Offset toScreen(Offset meters) => Offset(
          centerScreen.dx + (meters.dx - centerMeters.dx) * scale,
          centerScreen.dy + (meters.dy - centerMeters.dy) * scale,
        );

    final screenPoints = checkpointPoints.map(toScreen).toList();
    final estimateScreen =
        estimatePoint == null ? null : toScreen(estimatePoint);

    _drawPolyline(canvas, screenPoints);
    _drawCheckpointMarkers(canvas, screenPoints);
    if (estimateScreen != null) {
      _drawEstimate(canvas, screenPoints.last, estimateScreen);
    }
  }

  void _drawPolyline(Canvas canvas, List<Offset> screenPoints) {
    if (screenPoints.length < 2) return;

    final linePaint = Paint()
      ..color = const Color(0xFFD4A017)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(screenPoints.first.dx, screenPoints.first.dy);
    for (final p in screenPoints.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linePaint);
  }

  void _drawCheckpointMarkers(Canvas canvas, List<Offset> screenPoints) {
    for (var i = 0; i < screenPoints.length; i++) {
      final isLast = i == screenPoints.length - 1;
      final r = isLast ? 6.0 : 4.0;
      canvas.drawCircle(screenPoints[i], r, Paint()..color = const Color(0xFFE8D5A3));
      canvas.drawCircle(
        screenPoints[i],
        r,
        Paint()
          ..color = const Color(0xFF1A1208)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawEstimate(Canvas canvas, Offset from, Offset to) {
    _drawDashedLine(
      canvas,
      from,
      to,
      dashLength: 6,
      gapLength: 5,
      paint: Paint()
        ..color = const Color(0xFFFFDD44)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(to, 6, Paint()..color = const Color(0xFFFFDD44));
    canvas.drawCircle(
      to,
      9,
      Paint()
        ..color = const Color(0x55FFDD44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
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
    if (totalLen == 0) return;
    final nx = dx / totalLen;
    final ny = dy / totalLen;

    double drawn = 0;
    bool drawing = true;
    while (drawn < totalLen) {
      final segLen = drawing ? dashLength : gapLength;
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

  @override
  bool shouldRepaint(_PathPainter oldDelegate) =>
      oldDelegate.checkpoints != checkpoints ||
      oldDelegate.liveEstimate != liveEstimate;
}
