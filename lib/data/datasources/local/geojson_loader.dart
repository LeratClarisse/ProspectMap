import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/road_model.dart';

class GeoJsonLoader {
  static const String _geoJsonPath = 'assets/geojsons/doubs_belfort_hautesaone_cities_roads_with_cities.geojson';

  /// Load and parse GeoJSON file
  Future<List<RoadModel>> loadRoads() async {
    try {
      // Load GeoJSON file from assets
      final geoJsonString = await rootBundle.loadString(_geoJsonPath);
      final geoJson = json.decode(geoJsonString);

      // Group roads by name for merging connected segments
      final Map<String, List<RoadModel>> roadGroups = {};

      // Parse each feature
      for (final feature in geoJson['features']) {
        final geometry = feature['geometry'];
        final properties = feature['properties'];
        final name = properties['name'];

        // Only process LineString features with names
        if (geometry['type'] == 'LineString' && name != null) {
          final road = RoadModel.fromGeoJsonFeature(feature);

          // Group roads by name
          roadGroups.putIfAbsent(name, () => []);

          // Try to merge with existing road group if segments are connected
          bool merged = false;
          for (int i = 0; i < roadGroups[name]!.length; i++) {
            final existingRoad = roadGroups[name]![i];
            if (_areRoadsConnected(existingRoad, road)) {
              roadGroups[name]![i] = existingRoad.mergeWith(road);
              merged = true;
              break;
            }
          }

          // If not merged, add as new road group
          if (!merged) {
            roadGroups[name]!.add(road);
          }
        }
      }

      // Flatten grouped roads
      final List<RoadModel> consolidatedRoads = [];
      roadGroups.forEach((name, roads) {
        consolidatedRoads.addAll(roads);
      });

      return consolidatedRoads;
    } catch (e) {
      throw Exception('Failed to load GeoJSON roads: $e');
    }
  }

  /// Check if two roads have connected segments
  bool _areRoadsConnected(RoadModel road1, RoadModel road2) {
    for (final segment1 in road1.segments) {
      for (final segment2 in road2.segments) {
        if (segment1.isConnectedTo(segment2)) {
          return true;
        }
      }
    }
    return false;
  }
}
