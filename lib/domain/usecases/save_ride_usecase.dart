import '../entities/ride.dart';
import '../repositories/ride_repository.dart';

class SaveRideUseCase {
  final RideRepository rideRepository;

  const SaveRideUseCase({
    required this.rideRepository,
  });

  /// Save a ride for a specific road
  Future<void> call(String roadId, DateTime date) async {
    final ride = Ride(date: date);
    await rideRepository.saveRide(roadId, ride);
  }
}
