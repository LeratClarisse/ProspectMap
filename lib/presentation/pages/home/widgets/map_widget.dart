import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../domain/entities/road.dart';
import '../../../../domain/entities/location.dart';
import '../../../../data/models/location_model.dart';
import '../../../../data/models/segment_model.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final Location? userLocation;
  final List<Road> roads;
  final Road? selectedRoad;
  final bool showColoredSegments;
  final ValueChanged<Location>? onTap;

  const MapWidget({
    Key? key,
    required this.mapController,
    this.userLocation,
    required this.roads,
    this.selectedRoad,
    required this.showColoredSegments,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: _getInitialCenter(),
        initialZoom: 13.0,
        onTap: (tapPosition, point) {
          final location = LocationModel.fromLatLng(point);
          onTap?.call(location);
        },
        minZoom: 10.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
          enableMultiFingerGestureRace: true,
        ),
      ),
      children: [
        // Base tile layer
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.app',
          tileProvider: NetworkTileProvider(
            headers: {
              'User-Agent': 'ProspectMap-App/1.0',
            },
          ),
          keepBuffer: 2,
        ),

        // User location marker
        if (userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LocationModel(
                  latitude: userLocation!.latitude,
                  longitude: userLocation!.longitude,
                ).toLatLng(),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            ],
          ),

        // Colored road segments
        if (showColoredSegments) PolylineLayer(polylines: _buildColoredSegments()),

        // Selected road segments
        if (selectedRoad != null) PolylineLayer(polylines: _buildSelectedRoadSegments()),
      ],
    );
  }

  LatLng _getInitialCenter() {
    if (userLocation != null) {
      return LocationModel(
        latitude: userLocation!.latitude,
        longitude: userLocation!.longitude,
      ).toLatLng();
    }
    // Default to LaForet Audincourt
    return LatLng(47.4800, 6.8400);
  }

  List<Polyline> _buildColoredSegments() {
    final polylines = <Polyline>[];

    for (final road in roads) {
      if (road.hasRides) {
        final color = _getRoadColor(road);
        for (final segment in road.segments) {
          final segmentModel = SegmentModel(
            points: segment.points,
            city: segment.city,
          );

          polylines.add(
            Polyline(
              points: segmentModel.toLatLngList(),
              strokeWidth: 3.0,
              color: color.withValues(alpha: 0.7),
              borderColor: Colors.black,
              borderStrokeWidth: 0.3,
            ),
          );
        }
      }
    }

    return polylines;
  }

  List<Polyline> _buildSelectedRoadSegments() {
    if (selectedRoad == null) return [];

    final polylines = <Polyline>[];
    final color = _getRoadColor(selectedRoad!);

    for (final segment in selectedRoad!.segments) {
      final segmentModel = SegmentModel(
        points: segment.points,
        city: segment.city,
      );

      polylines.add(
        Polyline(
          points: segmentModel.toLatLngList(),
          strokeWidth: 4.0,
          color: color,
          borderColor: Colors.black,
          borderStrokeWidth: 0.5,
        ),
      );
    }

    return polylines;
  }

  Color _getRoadColor(Road road) {
    switch (road.color) {
      case RoadColor.green:
        return Colors.green;
      case RoadColor.orange:
        return Colors.orange;
      case RoadColor.red:
        return Colors.red;
    }
  }
}
