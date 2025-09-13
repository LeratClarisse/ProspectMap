import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/road.dart';
import '../../../../domain/entities/location.dart';
import '../../../../domain/usecases/get_roads_usecase.dart';
import '../../../../domain/usecases/search_roads_usecase.dart';
import '../../../../domain/usecases/save_ride_usecase.dart';
import '../../../../domain/usecases/delete_ride_usecase.dart';
import '../../../../domain/usecases/get_location_usecase.dart';
import '../../../../domain/usecases/calculate_road_distance_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetRoadsUseCase getRoadsUseCase;
  final SearchRoadsUseCase searchRoadsUseCase;
  final SaveRideUseCase saveRideUseCase;
  final DeleteRideUseCase deleteRideUseCase;
  final GetLocationUseCase getLocationUseCase;
  final CalculateRoadDistanceUseCase calculateRoadDistanceUseCase;

  StreamSubscription<Location>? _locationSubscription;
  Timer? _searchTimer;

  HomeCubit({
    required this.getRoadsUseCase,
    required this.searchRoadsUseCase,
    required this.saveRideUseCase,
    required this.deleteRideUseCase,
    required this.getLocationUseCase,
    required this.calculateRoadDistanceUseCase,
  }) : super(HomeState.initial());

  /// Initialize the app - load roads and start location tracking
  Future<void> initialize() async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      // Load roads and start location tracking in parallel
      await Future.wait([
        _loadRoads(),
        _startLocationTracking(),
      ]);

      emit(state.copyWith(status: HomeStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load all roads with rides
  Future<void> _loadRoads() async {
    emit(state.copyWith(status: HomeStatus.loadingRoads));

    try {
      final roads = await getRoadsUseCase();
      emit(state.copyWith(
        roads: roads,
        status: HomeStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Failed to load roads: $e',
      ));
    }
  }

  /// Start location tracking
  Future<void> _startLocationTracking() async {
    try {
      // Get initial location
      final initialLocation = await getLocationUseCase();
      if (initialLocation != null) {
        emit(state.copyWith(userLocation: initialLocation));
      }

      // Start location stream
      _locationSubscription?.cancel();
      _locationSubscription = getLocationUseCase.getLocationStream().listen(
        (location) {
          emit(state.copyWith(userLocation: location));
        },
        onError: (error) {
          // Handle location error silently or show a subtle indicator
        },
      );
    } catch (e) {
      // Location errors are not critical, continue without location
    }
  }

  /// Handle search query changes with debouncing
  void onSearchChanged(String query) {
    emit(state.copyWith(
      searchQuery: query,
      showSearchSuggestions: query.isNotEmpty,
    ));

    // Cancel previous search timer
    _searchTimer?.cancel();

    if (query.trim().isEmpty) {
      emit(state.copyWith(
        searchResults: [],
        showSearchSuggestions: false,
      ));
      return;
    }

    // Debounce search to avoid too many API calls
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    emit(state.copyWith(status: HomeStatus.searching));

    try {
      final results = await searchRoadsUseCase(query);
      emit(state.copyWith(
        searchResults: results.take(5).toList(), // Limit to 5 results
        status: HomeStatus.success,
        showSearchSuggestions: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Search failed: $e',
      ));
    }
  }

  /// Handle search focus changes
  void onSearchFocusChanged(bool hasFocus) {
    if (hasFocus) {
      emit(state.copyWith(
        showSearchSuggestions: state.searchQuery.isNotEmpty,
        isPanelExpanded: false,
      ));
    } else {
      emit(state.copyWith(showSearchSuggestions: false));
    }
  }

  /// Select a road from search results or map tap
  void selectRoad(Road? road) {
    emit(state.copyWith(
      selectedRoad: road,
      isPanelExpanded: false,
      showSearchSuggestions: false,
    ));
  }

  /// Handle map tap to select road
  void onMapTapped(Location location) {
    // Hide search suggestions first
    if (state.showSearchSuggestions) {
      emit(state.copyWith(showSearchSuggestions: false));
      return;
    }

    // Find closest road
    final closestRoad = calculateRoadDistanceUseCase.findClosestRoad(
      state.roads,
      location,
    );

    if (closestRoad != null) {
      if (state.selectedRoad?.id == closestRoad.id) {
        // Tapped same road - deselect
        emit(state.clearSelectedRoad());
      } else {
        // Select new road
        selectRoad(closestRoad);
      }
    } else {
      // Tapped outside any road - deselect
      emit(state.clearSelectedRoad());
    }
  }

  /// Clear search
  void clearSearch() {
    _searchTimer?.cancel();
    emit(state.clearSearch().clearSelectedRoad());
  }

  /// Toggle info panel
  void togglePanel() {
    emit(state.copyWith(
      isPanelExpanded: !state.isPanelExpanded,
    ));
  }

  /// Toggle colored segments visibility
  void toggleColoredSegments() {
    emit(state.copyWith(
      showColoredSegments: !state.showColoredSegments,
    ));
  }

  /// Save ride date for selected road
  Future<void> saveRideDate(DateTime date) async {
    if (state.selectedRoad == null) return;

    try {
      await saveRideUseCase(state.selectedRoad!.id, date);

      // Reload roads to get updated data
      await _loadRoads();

      // Update selected road with new ride data
      final updatedRoad = state.roads.firstWhere(
        (road) => road.id == state.selectedRoad!.id,
      );
      emit(state.copyWith(selectedRoad: updatedRoad));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Failed to save ride: $e',
      ));
    }
  }

  /// Delete ride date for selected road
  Future<void> deleteRideDate(DateTime date) async {
    if (state.selectedRoad == null) return;

    try {
      await deleteRideUseCase(state.selectedRoad!.id, date);

      // Reload roads to get updated data
      await _loadRoads();

      // Update selected road with new ride data
      final updatedRoad = state.roads.firstWhere(
        (road) => road.id == state.selectedRoad!.id,
      );
      emit(state.copyWith(selectedRoad: updatedRoad));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Failed to delete ride: $e',
      ));
    }
  }

  /// Move map to user location
  void centerOnUserLocation() {
    // This will be handled by the UI layer
    // Cubit just provides the current user location
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _searchTimer?.cancel();
    return super.close();
  }
}
