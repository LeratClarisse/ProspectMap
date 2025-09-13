import '../../domain/entities/road.dart';
import '../../domain/repositories/road_repository.dart';
import '../datasources/local/geojson_loader.dart';
import '../datasources/local/hive_service.dart';
import '../models/road_model.dart';

class RoadRepositoryImpl implements RoadRepository {
  final GeoJsonLoader geoJsonLoader;
  final HiveService hiveService;

  RoadRepositoryImpl({
    required this.geoJsonLoader,
    required this.hiveService,
  });

  @override
  Future<List<Road>> getAllRoads() async {
    try {
      // Try to get from cache first
      if (hiveService.isCacheValid()) {
        final cachedData = hiveService.getCachedRoads();
        if (cachedData != null) {
          return cachedData.map((data) => RoadModel.fromMap(data)).cast<Road>().toList();
        }
      }

      // Load from GeoJSON
      final roads = await geoJsonLoader.loadRoads();

      // Cache the results
      final roadMaps = roads.map((road) => road.toMap()).toList();
      await hiveService.cacheRoads(roadMaps);

      return roads.cast<Road>();
    } catch (e) {
      throw Exception('Failed to load roads: $e');
    }
  }

  @override
  Future<List<Road>> searchRoads(String query) async {
    final allRoads = await getAllRoads();
    final queryLower = query.toLowerCase().trim();

    if (queryLower.isEmpty) return [];

    return allRoads.where((road) {
      final name = road.name.toLowerCase();
      return name.contains(queryLower) || name.split(' ').any((word) => word.startsWith(queryLower));
    }).toList();
  }

  @override
  Future<Road?> getRoadById(String id) async {
    final allRoads = await getAllRoads();
    try {
      return allRoads.firstWhere((road) => road.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Road>> getRoadsByColor(RoadColor color) async {
    final allRoads = await getAllRoads();
    return allRoads.where((road) => road.color == color).toList();
  }

  @override
  Future<List<Road>> getRoadsByCity(String city) async {
    final allRoads = await getAllRoads();
    return allRoads.where((road) => road.city.toLowerCase().contains(city.toLowerCase())).toList();
  }
}
