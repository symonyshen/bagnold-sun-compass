/// Represents the position of the sun in the sky.
class SunPosition {
  /// Azimuth in degrees from North, measured clockwise (0 = N, 90 = E, 180 = S, 270 = W).
  final double azimuth;

  /// Altitude in degrees above the horizon. Negative means below horizon (night).
  final double altitude;

  const SunPosition({
    required this.azimuth,
    required this.altitude,
  });

  bool get isAboveHorizon => altitude > 0;

  @override
  String toString() =>
      'SunPosition(azimuth: ${azimuth.toStringAsFixed(1)}°, altitude: ${altitude.toStringAsFixed(1)}°)';
}
