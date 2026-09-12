/// Holds the application-level state passed between screens.
class AppState {
  /// Latitude of the user's position, in decimal degrees.
  final double latitude;

  /// Longitude of the user's position, in decimal degrees.
  final double longitude;

  /// The desired travel heading in degrees (0–360, clockwise from North).
  final double desiredHeading;

  /// When the coordinates were last set or confirmed by the user.
  final DateTime coordsUpdatedAt;

  const AppState({
    required this.latitude,
    required this.longitude,
    required this.desiredHeading,
    required this.coordsUpdatedAt,
  });

  /// Creates an initial state with a given location and a default heading of 0°.
  factory AppState.initial({
    required double latitude,
    required double longitude,
  }) {
    return AppState(
      latitude: latitude,
      longitude: longitude,
      desiredHeading: 0,
      coordsUpdatedAt: DateTime.now(),
    );
  }

  AppState copyWith({
    double? latitude,
    double? longitude,
    double? desiredHeading,
    DateTime? coordsUpdatedAt,
  }) {
    return AppState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      desiredHeading: desiredHeading ?? this.desiredHeading,
      coordsUpdatedAt: coordsUpdatedAt ?? this.coordsUpdatedAt,
    );
  }

  @override
  String toString() => 'AppState(lat: $latitude, lng: $longitude, '
      'heading: $desiredHeading°, updatedAt: $coordsUpdatedAt)';
}
