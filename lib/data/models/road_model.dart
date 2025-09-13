import '../../domain/entities/road.dart';
import '../../domain/entities/segment.dart';
import '../../domain/entities/ride.dart';
import 'segment_model.dart';
import 'ride_model.dart';

class RoadModel extends Road {
  const RoadModel({
    required String id,
    required String name,
    required String city,
    required List<Segment> segments,
    required List<Ride> rides,
  }) : super(id: id, name: name, city: city, segments: segments, rides: rides);

  /// Create from GeoJSON feature
  factory RoadModel.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'];
    final geometry = feature['geometry'];

    final segment = SegmentModel.fromGeoJson(geometry, properties['city']);

    return RoadModel(
      id: properties['@id']?.toString() ?? '',
      name: properties['name']?.toString() ?? '',
      city: properties['city']?.toString() ?? '',
      segments: [segment],
      rides: [], // Rides will be loaded separately
    );
  }

  /// Create from Map (for caching/storage)
  factory RoadModel.fromMap(Map<String, dynamic> map) {
    final segmentsList = map['segments'] as List;
    final segments = segmentsList.map((seg) => SegmentModel.fromMap(Map<String, dynamic>.from(seg))).cast<Segment>().toList();

    final ridesList = map['rides'] as List? ?? [];
    final rides = ridesList.map((ride) => RideModel.fromMap(Map<String, dynamic>.from(ride))).cast<Ride>().toList();

    return RoadModel(
      id: map['id'],
      name: map['name'],
      city: map['city'],
      segments: segments,
      rides: rides,
    );
  }

  /// Convert to Map (for caching/storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'segments': segments
          .map((seg) => SegmentModel(
                points: seg.points,
                city: seg.city,
              ).toMap())
          .toList(),
      'rides': rides.map((ride) => RideModel(date: ride.date).toMap()).toList(),
    };
  }

  /// Merge with another road model (for grouping segments)
  RoadModel mergeWith(RoadModel other) {
    // if (id != other.id || name != other.name) {
    //   print("exception");
    //   print(other);
    //   print(this);
    //   throw ArgumentError('Cannot merge roads with different IDs or names');
    // }

    return RoadModel(
      id: id,
      name: name,
      city: city,
      segments: [...segments, ...other.segments],
      rides: rides, // Keep original rides
    );
  }

  /// Add segment to this road
  RoadModel addSegment(Segment segment) {
    return RoadModel(
      id: id,
      name: name,
      city: city,
      segments: [...segments, segment],
      rides: rides,
    );
  }
}
