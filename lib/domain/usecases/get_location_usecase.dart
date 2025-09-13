import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetLocationUseCase {
  final LocationRepository locationRepository;

  const GetLocationUseCase({
    required this.locationRepository,
  });

  /// Get current location with permission check
  Future<Location?> call() async {
    final hasPermission = await locationRepository.hasLocationPermission();
    if (!hasPermission) {
      final granted = await locationRepository.requestLocationPermission();
      if (!granted) return null;
    }

    return await locationRepository.getCurrentLocation();
  }

  /// Get location stream with permission check
  Stream<Location> getLocationStream() async* {
    final hasPermission = await locationRepository.hasLocationPermission();
    if (!hasPermission) {
      final granted = await locationRepository.requestLocationPermission();
      if (!granted) return;
    }

    yield* locationRepository.getLocationStream();
  }
}
