import '../entities/road.dart';

abstract class RoadRepository {
  /// Get all roads from data source
  Future<List<Road>> getAllRoads();

  /// Search roads by name or city
  Future<List<Road>> searchRoads(String query);

  /// Get a specific road by ID
  Future<Road?> getRoadById(String id);

  /// Get roads filtered by color/last ride date
  Future<List<Road>> getRoadsByColor(RoadColor color);

  /// Get roads by city
  Future<List<Road>> getRoadsByCity(String city);
}
