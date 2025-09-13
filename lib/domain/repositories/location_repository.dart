import '../entities/location.dart';

abstract class LocationRepository {
  /// Get current user location
  Future<Location?> getCurrentLocation();

  /// Start listening to location updates
  Stream<Location> getLocationStream();

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission();

  /// Request location permissions
  Future<bool> requestLocationPermission();
}
