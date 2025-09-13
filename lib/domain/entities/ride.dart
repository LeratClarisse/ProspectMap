import 'package:equatable/equatable.dart';

class Ride extends Equatable {
  final DateTime date;

  const Ride({
    required this.date,
  });

  @override
  List<Object> get props => [date];

  /// Get the number of days since this ride
  int get daysSinceRide => DateTime.now().difference(date).inDays;

  /// Check if the ride was today
  bool get isToday => daysSinceRide == 0;

  /// Check if the ride was yesterday
  bool get isYesterday => daysSinceRide == 1;

  /// Check if the ride was within the last week
  bool get isWithinWeek => daysSinceRide <= 7;

  /// Check if the ride was within the last month
  bool get isWithinMonth => daysSinceRide <= 30;

  /// Get formatted relative date text in French
  String get relativeDate {
    if (isToday) {
      return 'Parcouru aujourd\'hui';
    } else if (isYesterday) {
      return 'Parcouru hier';
    } else if (isWithinWeek) {
      return 'Parcouru il y a $daysSinceRide jours';
    } else if (isWithinMonth) {
      return 'Parcouru il y a ${(daysSinceRide / 7).round()} semaines';
    } else {
      return 'Parcouru il y a ${(daysSinceRide / 30).round()} mois';
    }
  }

  @override
  String toString() => 'Ride(date: $date)';
}
