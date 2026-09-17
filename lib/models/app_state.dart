import 'checkpoint.dart';

/// Holds the application-level state passed between screens.
class AppState {
  /// The full history of confirmed coordinate checkpoints (initial entry +
  /// every manual "Update Location"). Always non-empty — the last entry is
  /// the current dead-reckoning origin.
  final List<Checkpoint> checkpoints;

  /// The desired travel heading in degrees (0–360, clockwise from North),
  /// as currently set on the dial.
  final double desiredHeading;

  /// Walking speed in km/h, used for dead reckoning. `0` means dead
  /// reckoning is off — the position shown is just the last checkpoint.
  final double speedKmh;

  const AppState({
    required this.checkpoints,
    required this.desiredHeading,
    required this.speedKmh,
  });

  /// Latitude of the current dead-reckoning origin, in decimal degrees.
  double get latitude => checkpoints.last.latitude;

  /// Longitude of the current dead-reckoning origin, in decimal degrees.
  double get longitude => checkpoints.last.longitude;

  /// When the current origin checkpoint was confirmed.
  DateTime get coordsUpdatedAt => checkpoints.last.timestamp;

  /// Creates an initial state with a given location and a default heading of 0°.
  factory AppState.initial({
    required double latitude,
    required double longitude,
  }) {
    return AppState(
      checkpoints: [
        Checkpoint(
          latitude: latitude,
          longitude: longitude,
          heading: 0,
          timestamp: DateTime.now(),
        ),
      ],
      desiredHeading: 0,
      speedKmh: 0,
    );
  }

  AppState copyWith({
    List<Checkpoint>? checkpoints,
    double? desiredHeading,
    double? speedKmh,
  }) {
    return AppState(
      checkpoints: checkpoints ?? this.checkpoints,
      desiredHeading: desiredHeading ?? this.desiredHeading,
      speedKmh: speedKmh ?? this.speedKmh,
    );
  }

  /// Appends a new confirmed checkpoint (e.g. from "Update Location"),
  /// snapshotting the current [desiredHeading] into it. This becomes the
  /// new dead-reckoning origin.
  AppState withNewCheckpoint({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) {
    return copyWith(checkpoints: [
      ...checkpoints,
      Checkpoint(
        latitude: latitude,
        longitude: longitude,
        heading: desiredHeading,
        timestamp: timestamp,
      ),
    ]);
  }

  @override
  String toString() => 'AppState(lat: $latitude, lng: $longitude, '
      'heading: $desiredHeading°, speed: $speedKmh km/h, '
      'checkpoints: ${checkpoints.length})';
}
