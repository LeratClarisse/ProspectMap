import '../entities/road.dart';
import '../repositories/road_repository.dart';
import '../repositories/ride_repository.dart';

class GetRoadsUseCase {
  final RoadRepository roadRepository;
  final RideRepository rideRepository;

  const GetRoadsUseCase({
    required this.roadRepository,
    required this.rideRepository,
  });

  /// Get all roads with their associated rides
  Future<List<Road>> call() async {
    final roads = await roadRepository.getAllRoads();
    final allRides = await rideRepository.getAllRides();

    // Merge roads with their rides
    return roads.map((road) {
      final roadRides = allRides[road.id] ?? [];
      return Road(
        id: road.id,
        name: road.name,
        city: road.city,
        segments: road.segments,
        rides: roadRides,
      );
    }).toList();
  }
}
