import '../../domain/entities/ride.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/local/hive_service.dart';
import '../models/ride_model.dart';

class RideRepositoryImpl implements RideRepository {
  final HiveService hiveService;

  RideRepositoryImpl({
    required this.hiveService,
  });

  @override
  Future<List<Ride>> getRidesForRoad(String roadId) async {
    final rideDates = hiveService.getRideDatesForRoad(roadId);
    return rideDates.map((dateStr) => RideModel.fromIsoString(dateStr)).cast<Ride>().toList();
  }

  @override
  Future<void> saveRide(String roadId, Ride ride) async {
    final rideModel = RideModel(date: ride.date);
    await hiveService.saveRideForRoad(roadId, rideModel.toIsoString());
  }

  @override
  Future<void> deleteRide(String roadId, Ride ride) async {
    final rideModel = RideModel(date: ride.date);
    await hiveService.removeRideForRoad(roadId, rideModel.toIsoString());
  }

  @override
  Future<Map<String, List<Ride>>> getAllRides() async {
    final allRidesData = hiveService.getAllRides();
    final Map<String, List<Ride>> allRides = {};

    allRidesData.forEach((roadId, rideDates) {
      allRides[roadId] = rideDates.map((dateStr) => RideModel.fromIsoString(dateStr)).cast<Ride>().toList();
    });

    return allRides;
  }

  @override
  Future<void> clearRidesForRoad(String roadId) async {
    await hiveService.ridesBox.delete(roadId);
  }
}
