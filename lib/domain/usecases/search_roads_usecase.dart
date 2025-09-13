import '../entities/road.dart';
import '../repositories/road_repository.dart';
import '../repositories/ride_repository.dart';

class SearchRoadsUseCase {
  final RoadRepository roadRepository;
  final RideRepository rideRepository;

  const SearchRoadsUseCase({
    required this.roadRepository,
    required this.rideRepository,
  });

  /// Search roads with query and sort by relevance and last ride date
  Future<List<Road>> call(String query) async {
    if (query.trim().isEmpty) return [];

    final roads = await roadRepository.searchRoads(query);
    final allRides = await rideRepository.getAllRides();

    // Merge with rides
    final roadsWithRides = roads.map((road) {
      final roadRides = allRides[road.id] ?? [];
      return Road(
        id: road.id,
        name: road.name,
        city: road.city,
        segments: road.segments,
        rides: roadRides,
      );
    }).toList();

    // Sort by relevance and last visit
    return _sortRoadsByRelevance(roadsWithRides, query);
  }

  List<Road> _sortRoadsByRelevance(List<Road> roads, String query) {
    final queryLower = query.toLowerCase().trim();

    roads.sort((a, b) {
      final nameA = a.name.toLowerCase();
      final nameB = b.name.toLowerCase();

      // Exact match priority
      if (nameA == queryLower) return -1;
      if (nameB == queryLower) return 1;

      // Starts with query priority
      if (nameA.startsWith(queryLower) && !nameB.startsWith(queryLower)) return -1;
      if (nameB.startsWith(queryLower) && !nameA.startsWith(queryLower)) return 1;

      // If both have same relevance, sort by last ride date
      if (a.hasRides && b.hasRides) {
        return b.lastRideDate!.compareTo(a.lastRideDate!);
      }
      if (a.hasRides && !b.hasRides) return -1;
      if (!a.hasRides && b.hasRides) return 1;

      // Default alphabetical
      return nameA.compareTo(nameB);
    });

    return roads;
  }
}
