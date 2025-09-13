import 'package:flutter/material.dart';
import 'data/datasources/local/hive_service.dart';
import 'data/datasources/local/geojson_loader.dart';
import 'data/datasources/remote/location_service.dart';
import 'data/repositories/road_repository_impl.dart';
import 'data/repositories/ride_repository_impl.dart';
import 'data/repositories/location_repository_impl.dart';
import 'domain/usecases/get_roads_usecase.dart';
import 'domain/usecases/search_roads_usecase.dart';
import 'domain/usecases/save_ride_usecase.dart';
import 'domain/usecases/delete_ride_usecase.dart';
import 'domain/usecases/get_location_usecase.dart';
import 'domain/usecases/calculate_road_distance_usecase.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final hiveService = HiveService();
  await hiveService.init();

  final geoJsonLoader = GeoJsonLoader();
  final locationService = LocationService();

  // Create repositories
  final roadRepository = RoadRepositoryImpl(
    geoJsonLoader: geoJsonLoader,
    hiveService: hiveService,
  );

  final rideRepository = RideRepositoryImpl(
    hiveService: hiveService,
  );

  final locationRepository = LocationRepositoryImpl(
    locationService: locationService,
  );

  // Create use cases
  final getRoadsUseCase = GetRoadsUseCase(
    roadRepository: roadRepository,
    rideRepository: rideRepository,
  );

  final searchRoadsUseCase = SearchRoadsUseCase(
    roadRepository: roadRepository,
    rideRepository: rideRepository,
  );

  final saveRideUseCase = SaveRideUseCase(
    rideRepository: rideRepository,
  );

  final deleteRideUseCase = DeleteRideUseCase(
    rideRepository: rideRepository,
  );

  final getLocationUseCase = GetLocationUseCase(
    locationRepository: locationRepository,
  );

  final calculateRoadDistanceUseCase = CalculateRoadDistanceUseCase();

  // Run app
  runApp(
    App(
      getRoadsUseCase: getRoadsUseCase,
      searchRoadsUseCase: searchRoadsUseCase,
      saveRideUseCase: saveRideUseCase,
      deleteRideUseCase: deleteRideUseCase,
      getLocationUseCase: getLocationUseCase,
      calculateRoadDistanceUseCase: calculateRoadDistanceUseCase,
    ),
  );
}
