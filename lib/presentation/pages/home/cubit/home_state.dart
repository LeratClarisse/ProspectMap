import 'package:equatable/equatable.dart';
import '../../../../../../domain/entities/road.dart';
import '../../../../../../domain/entities/location.dart';

enum HomeStatus {
  initial,
  loading,
  loadingRoads,
  searching,
  success,
  error,
}

class HomeState extends Equatable {
  final HomeStatus status;
  final List<Road> roads;
  final List<Road> searchResults;
  final Road? selectedRoad;
  final Location? userLocation;
  final String searchQuery;
  final bool showSearchSuggestions;
  final bool isPanelExpanded;
  final bool showColoredSegments;
  final String? errorMessage;

  const HomeState({
    required this.status,
    required this.roads,
    required this.searchResults,
    this.selectedRoad,
    this.userLocation,
    required this.searchQuery,
    required this.showSearchSuggestions,
    required this.isPanelExpanded,
    required this.showColoredSegments,
    this.errorMessage,
  });

  factory HomeState.initial() {
    return const HomeState(
      status: HomeStatus.initial,
      roads: [],
      searchResults: [],
      selectedRoad: null,
      userLocation: null,
      searchQuery: '',
      showSearchSuggestions: false,
      isPanelExpanded: false,
      showColoredSegments: true,
      errorMessage: null,
    );
  }

  HomeState copyWith({
    HomeStatus? status,
    List<Road>? roads,
    List<Road>? searchResults,
    Road? selectedRoad,
    Location? userLocation,
    String? searchQuery,
    bool? showSearchSuggestions,
    bool? isPanelExpanded,
    bool? showColoredSegments,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      roads: roads ?? this.roads,
      searchResults: searchResults ?? this.searchResults,
      selectedRoad: selectedRoad ?? this.selectedRoad,
      userLocation: userLocation ?? this.userLocation,
      searchQuery: searchQuery ?? this.searchQuery,
      showSearchSuggestions: showSearchSuggestions ?? this.showSearchSuggestions,
      isPanelExpanded: isPanelExpanded ?? this.isPanelExpanded,
      showColoredSegments: showColoredSegments ?? this.showColoredSegments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  HomeState clearSelectedRoad() {
    return copyWith(
      selectedRoad: null,
      isPanelExpanded: false,
    );
  }

  HomeState clearSearch() {
    return copyWith(
      searchQuery: '',
      searchResults: [],
      showSearchSuggestions: false,
    );
  }

  @override
  List<Object?> get props => [
        status,
        roads,
        searchResults,
        selectedRoad,
        userLocation,
        searchQuery,
        showSearchSuggestions,
        isPanelExpanded,
        showColoredSegments,
        errorMessage,
      ];
}
