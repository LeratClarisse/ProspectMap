import '../../domain/entities/location.dart';
import 'package:latlong2/latlong.dart';

class LocationModel extends Location {
  const LocationModel({
    required double latitude,
    required double longitude,
  }) : super(latitude: latitude, longitude: longitude);

  /// Convert from LatLng (flutter_map)
  factory LocationModel.fromLatLng(LatLng latLng) {
    return LocationModel(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );
  }

  /// Convert to LatLng (flutter_map)
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  /// Create from JSON coordinates [lng, lat] (GeoJSON format)
  factory LocationModel.fromGeoJsonCoordinates(List<double> coordinates) {
    return LocationModel(
      longitude: coordinates[0], // GeoJSON is [lon, lat]
      latitude: coordinates[1],
    );
  }

  /// Convert to JSON coordinates [lng, lat] (GeoJSON format)
  List<double> toGeoJsonCoordinates() {
    return [longitude, latitude];
  }

  /// Create from Map
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
