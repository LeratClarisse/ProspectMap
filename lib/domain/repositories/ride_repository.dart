import '../entities/ride.dart';

abstract class RideRepository {
  /// Get all rides for a specific road
  Future<List<Ride>> getRidesForRoad(String roadId);

  /// Save a new ride for a road
  Future<void> saveRide(String roadId, Ride ride);

  /// Delete a ride for a road
  Future<void> deleteRide(String roadId, Ride ride);

  /// Get all rides across all roads
  Future<Map<String, List<Ride>>> getAllRides();

  /// Clear all rides for a road
  Future<void> clearRidesForRoad(String roadId);
}
