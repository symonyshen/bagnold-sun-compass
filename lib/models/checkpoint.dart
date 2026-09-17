/// A confirmed coordinate entry — either the initial position or a manual
/// "Update Location" override. Acts as the origin for dead reckoning until
/// the next checkpoint is confirmed.
class Checkpoint {
  /// Latitude of the checkpoint, in decimal degrees.
  final double latitude;

  /// Longitude of the checkpoint, in decimal degrees.
  final double longitude;

  /// The desired heading (0–360°, clockwise from North) at the moment this
  /// checkpoint was confirmed. Used as the fixed bearing for dead reckoning
  /// until the next checkpoint, rather than whatever heading the dial is
  /// currently showing.
  final double heading;

  /// When this checkpoint was confirmed.
  final DateTime timestamp;

  const Checkpoint({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.timestamp,
  });

  @override
  String toString() => 'Checkpoint(lat: $latitude, lng: $longitude, '
      'heading: $heading°, at: $timestamp)';
}
