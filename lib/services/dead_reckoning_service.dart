import 'dart:math' as math;

/// Estimates current position from a starting point, a fixed bearing, a
/// speed, and elapsed time — i.e. dead reckoning.
///
/// Uses the standard spherical-earth destination-point formula:
/// https://www.movable-type.co.uk/scripts/latlong.html#destPoint
class DeadReckoningService {
  const DeadReckoningService();

  static const _earthRadiusKm = 6371.0;

  /// Returns the estimated current position given a starting point,
  /// [headingDeg] (degrees clockwise from North), [speedKmh], and [elapsed]
  /// time since the starting point was confirmed.
  ({double latitude, double longitude}) estimatePosition({
    required double originLat,
    required double originLng,
    required double headingDeg,
    required double speedKmh,
    required Duration elapsed,
  }) {
    final distanceKm = speedKmh * elapsed.inSeconds / 3600.0;
    if (distanceKm <= 0) {
      return (latitude: originLat, longitude: originLng);
    }

    final angularDistance = distanceKm / _earthRadiusKm;
    final bearingRad = _toRad(headingDeg);
    final lat1 = _toRad(originLat);
    final lng1 = _toRad(originLng);

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angularDistance) +
          math.cos(lat1) * math.sin(angularDistance) * math.cos(bearingRad),
    );

    final lng2 = lng1 +
        math.atan2(
          math.sin(bearingRad) * math.sin(angularDistance) * math.cos(lat1),
          math.cos(angularDistance) - math.sin(lat1) * math.sin(lat2),
        );

    return (latitude: _toDeg(lat2), longitude: _toDeg(lng2));
  }

  double _toRad(double deg) => deg * math.pi / 180.0;

  double _toDeg(double rad) => rad * 180.0 / math.pi;
}
