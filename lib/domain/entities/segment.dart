import 'package:equatable/equatable.dart';
import 'location.dart';

class Segment extends Equatable {
  final List<Location> points;
  final String? city;

  const Segment({
    required this.points,
    this.city,
  });

  @override
  List<Object?> get props => [points, city];

  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;

  Location? get firstPoint => points.isNotEmpty ? points.first : null;
  Location? get lastPoint => points.isNotEmpty ? points.last : null;

  /// Check if this segment is connected to another segment
  bool isConnectedTo(Segment other) {
    if (isEmpty || other.isEmpty) return false;

    return firstPoint == other.firstPoint ||
        firstPoint == other.lastPoint ||
        lastPoint == other.firstPoint ||
        lastPoint == other.lastPoint;
  }
}
