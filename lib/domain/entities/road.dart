import 'package:equatable/equatable.dart';
import 'segment.dart';
import 'ride.dart';
import 'location.dart';

enum RoadColor {
  red, // Not visited recently (>45 days)
  orange, // Visited within 45 days
  green, // Visited within 30 days
}

class Road extends Equatable {
  final String id;
  final String name;
  final String city;
  final List<Segment> segments;
  final List<Ride> rides;

  const Road({
    required this.id,
    required this.name,
    required this.city,
    required this.segments,
    required this.rides,
  });

  @override
  List<Object> get props => [id, name, city, segments, rides];

  /// Check if this road has any rides recorded
  bool get hasRides => rides.isNotEmpty;

  /// Get the most recent ride date
  DateTime? get lastRideDate {
    if (rides.isEmpty) return null;
    return rides.map((r) => r.date).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Get the most recent ride
  Ride? get lastRide {
    if (rides.isEmpty) return null;
    return rides.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  /// Get color based on last ride date
  RoadColor get color {
    if (rides.isEmpty) return RoadColor.red;

    final lastRide = this.lastRide!;
    if (lastRide.daysSinceRide <= 30) {
      return RoadColor.green;
    } else if (lastRide.daysSinceRide <= 45) {
      return RoadColor.orange;
    } else {
      return RoadColor.red;
    }
  }

  /// Get relative date text for last ride
  String get lastRideText {
    if (rides.isEmpty) return 'Jamais parcouru';
    return lastRide!.relativeDate;
  }

  /// Calculate approximate center point of the road
  Location? get centerLocation {
    final allPoints = <Location>[];

    // Collect all points from all segments
    for (final segment in segments) {
      allPoints.addAll(segment.points);
    }

    if (allPoints.isEmpty) return null;

    // Calculate center point
    double totalLat = 0;
    double totalLng = 0;

    for (final point in allPoints) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return Location(
      latitude: totalLat / allPoints.length,
      longitude: totalLng / allPoints.length,
    );
  }

  /// Get sorted rides (most recent first)
  List<Ride> get sortedRides {
    final sortedList = List<Ride>.from(rides);
    sortedList.sort((a, b) => b.date.compareTo(a.date));
    return sortedList;
  }

  /// Create a copy with additional ride
  Road addRide(Ride ride) {
    return Road(
      id: id,
      name: name,
      city: city,
      segments: segments,
      rides: [...rides, ride],
    );
  }

  /// Create a copy without specific ride
  Road removeRide(Ride ride) {
    return Road(
      id: id,
      name: name,
      city: city,
      segments: segments,
      rides: rides.where((r) => r != ride).toList(),
    );
  }

  @override
  String toString() => 'Road(id: $id, name: $name, city: $city)';
}
