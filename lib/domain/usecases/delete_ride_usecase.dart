import '../repositories/ride_repository.dart';

class DeleteRideUseCase {
  final RideRepository rideRepository;

  const DeleteRideUseCase({
    required this.rideRepository,
  });

  /// Delete a specific ride for a road
  Future<void> call(String roadId, DateTime date) async {
    final rides = await rideRepository.getRidesForRoad(roadId);
    final rideToDelete = rides.firstWhere(
      (ride) => _isSameDate(ride.date, date),
      orElse: () => throw Exception('Ride not found'),
    );

    await rideRepository.deleteRide(roadId, rideToDelete);
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}
