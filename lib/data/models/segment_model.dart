import 'package:latlong2/latlong.dart';

import '../../domain/entities/segment.dart';
import '../../domain/entities/location.dart';
import 'location_model.dart';

class SegmentModel extends Segment {
  const SegmentModel({
    required List<Location> points,
    String? city,
  }) : super(points: points, city: city);

  /// Create from GeoJSON LineString geometry
  factory SegmentModel.fromGeoJson(
    Map<String, dynamic> geometry,
    String? city,
  ) {
    final coordinates = geometry['coordinates'] as List;
    final points = coordinates
        .map((coord) => LocationModel.fromGeoJsonCoordinates(
              List<double>.from(coord),
            ))
        .cast<Location>()
        .toList();

    return SegmentModel(
      points: points,
      city: city,
    );
  }

  /// Create from Map (for Hive storage)
  factory SegmentModel.fromMap(Map<String, dynamic> map) {
    final pointsList = map['points'] as List;
    final points = pointsList.map((point) => LocationModel.fromMap(Map<String, dynamic>.from(point))).cast<Location>().toList();

    return SegmentModel(
      points: points,
      city: map['city'],
    );
  }

  /// Convert to Map (for Hive storage)
  Map<String, dynamic> toMap() {
    return {
      'points': points
          .map((point) => LocationModel(
                latitude: point.latitude,
                longitude: point.longitude,
              ).toMap())
          .toList(),
      'city': city,
    };
  }

  /// Convert points to LatLng list for flutter_map
  List<LatLng> toLatLngList() {
    return points
        .map((point) => LocationModel(
              latitude: point.latitude,
              longitude: point.longitude,
            ).toLatLng())
        .toList();
  }
}
