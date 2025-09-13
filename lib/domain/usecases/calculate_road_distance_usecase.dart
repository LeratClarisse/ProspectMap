import '../entities/road.dart';
import '../entities/location.dart';
import '../entities/segment.dart';

class CalculateRoadDistanceUseCase {
  /// Find the closest road to a given location
  Road? findClosestRoad(List<Road> roads, Location location, {double threshold = 0.0002}) {
    double closestDistance = double.infinity;
    Road? closestRoad;

    for (final road in roads) {
      final distance = _calculateDistanceToRoad(location, road);
      if (distance < closestDistance) {
        closestDistance = distance;
        closestRoad = road;
      }
    }

    return (closestDistance < threshold) ? closestRoad : null;
  }

  /// Calculate minimum distance from a location to a road
  double _calculateDistanceToRoad(Location location, Road road) {
    double minDistance = double.infinity;

    for (final segment in road.segments) {
      final distance = _calculateDistanceToSegment(location, segment);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Calculate minimum distance from location to a segment
  double _calculateDistanceToSegment(Location location, Segment segment) {
    double minDist = double.infinity;
    final points = segment.points;

    for (int i = 0; i < points.length - 1; i++) {
      final dist = _distanceToLine(location, points[i], points[i + 1]);
      if (dist < minDist) {
        minDist = dist;
      }
    }

    return minDist;
  }

  /// Calculate distance from a point to a line segment
  double _distanceToLine(Location point, Location lineStart, Location lineEnd) {
    const double pi = 3.14159265359;

    // Convert to radians for accurate distance calculation
    double lat = point.latitude * (pi / 180);
    double lng = point.longitude * (pi / 180);
    double lat1 = lineStart.latitude * (pi / 180);
    double lng1 = lineStart.longitude * (pi / 180);
    double lat2 = lineEnd.latitude * (pi / 180);
    double lng2 = lineEnd.longitude * (pi / 180);

    // Calculate distances
    double A = lat - lat1;
    double B = lng - lng1;
    double C = lat2 - lat1;
    double D = lng2 - lng1;

    double dot = A * C + B * D;
    double lenSq = C * C + D * D;
    double param = lenSq != 0 ? dot / lenSq : -1;

    double xx, yy;

    if (param < 0 || (lat1 == lat2 && lng1 == lng2)) {
      xx = lat1;
      yy = lng1;
    } else if (param > 1) {
      xx = lat2;
      yy = lng2;
    } else {
      xx = lat1 + param * C;
      yy = lng1 + param * D;
    }

    // Calculate squared distance
    double dx = lat - xx;
    double dy = lng - yy;

    return dx * dx + dy * dy;
  }
}
