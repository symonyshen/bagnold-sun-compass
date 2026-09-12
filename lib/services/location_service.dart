import 'package:geolocator/geolocator.dart';

/// Provides GPS-based location functionality.
class LocationService {
  const LocationService();

  /// Requests the device's current GPS coordinates.
  ///
  /// Returns a record `(latitude, longitude)` on success, or `null` if:
  ///   - location services are disabled, or
  ///   - the user denies permission.
  ///
  /// Throws a [LocationServiceException] with a human-readable message on
  /// any unexpected failure so the UI can display it directly.
  Future<(double, double)?> getCurrentLocation() async {
    // Check if location services are enabled at the device level.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Location services are disabled on this device. '
        'Please enable them in Settings.',
      );
    }

    // Check / request permission.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // User explicitly denied — return null so the UI can fall back
        // gracefully to manual entry.
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Location permission is permanently denied. '
        'Please enable it in your device Settings.',
      );
    }

    // Fetch position with a reasonable timeout.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (position.latitude, position.longitude);
    } on TimeoutException {
      throw LocationServiceException(
        'GPS timed out. Please try again or enter coordinates manually.',
      );
    } catch (e) {
      throw LocationServiceException('Could not obtain location: $e');
    }
  }
}

/// Exception thrown when the location service encounters a recoverable error.
class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => message;
}
