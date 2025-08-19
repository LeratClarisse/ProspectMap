import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

import '../../../roads/domain/entities/road.dart';
import '../../../roads/domain/entities/road_segment.dart';
import '../../../../core/utils/geometry_utils.dart';

/// Loads and groups roads from a GeoJSON asset.
///
/// BUGFIX: Generate unique IDs per connected group, not just by road name,
/// to avoid collisions across cities with identical road names.
class AssetsRoadsDataSource {
  final String assetPath;
  AssetsRoadsDataSource({required this.assetPath});

  Future<List<Road>> fetchRoads() async {
    final String geoJsonString = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> geoJson = json.decode(geoJsonString);

    // Map of road name -> list of connected groups -> list of segments (points)
    final Map<String, List<List<List<LatLng>>>> roadGroups = {};

    for (final feature in (geoJson['features'] as List<dynamic>)) {
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>;
      final String? name = properties['name'];

      if (geometry['type'] == 'LineString' && name != null) {
        final List<dynamic> coords = geometry['coordinates'] as List<dynamic>;
        final List<LatLng> points = coords
            .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList(growable: false);

        roadGroups.putIfAbsent(name, () => []);

        bool added = false;
        for (final group in roadGroups[name]!) {
          if (GeometryUtils.areSegmentsConnected(group, points)) {
            group.add(points);
            added = true;
            break;
          }
        }
        if (!added) {
          roadGroups[name]!.add([points]);
        }
      }
    }

    final List<Road> roads = [];
    roadGroups.forEach((name, groups) {
      for (int i = 0; i < groups.length; i++) {
        final group = groups[i];
        // Unique, stable-ish id per connected group under the same road name
        final String id = '$name::$i';
        roads.add(
          Road(
            id: id,
            name: name,
            segments: group.map((pts) => RoadSegment(points: pts)).toList(growable: false),
          ),
        );
      }
    });

    return roads;
  }
}

