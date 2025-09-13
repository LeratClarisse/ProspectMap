import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/remote/location_service.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationService locationService;

  LocationRepositoryImpl({
    required this.locationService,
  });

  @override
  Future<Location?> getCurrentLocation() async {
    return await locationService.getCurrentLocation();
  }

  @override
  Stream<Location> getLocationStream() {
    return locationService.getLocationStream().cast<Location>();
  }

  @override
  Future<bool> hasLocationPermission() async {
    return await locationService.hasPermission();
  }

  @override
  Future<bool> requestLocationPermission() async {
    return await locationService.requestPermission();
  }
}
