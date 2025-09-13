import '../../domain/entities/ride.dart';

class RideModel extends Ride {
  const RideModel({
    required DateTime date,
  }) : super(date: date);

  /// Create from ISO string (Hive storage format)
  factory RideModel.fromIsoString(String isoString) {
    return RideModel(date: DateTime.parse(isoString));
  }

  /// Convert to ISO string (Hive storage format)
  String toIsoString() {
    return date.toIso8601String();
  }

  /// Create from Map
  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      date: DateTime.parse(map['date']),
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
    };
  }

  /// Create from timestamp (milliseconds since epoch)
  factory RideModel.fromTimestamp(int timestamp) {
    return RideModel(date: DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  /// Convert to timestamp (milliseconds since epoch)
  int toTimestamp() {
    return date.millisecondsSinceEpoch;
  }
}
