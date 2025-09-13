import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../../data/models/location_model.dart';
import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/search_suggestions_widget.dart';
import 'widgets/map_widget.dart';
import 'widgets/road_info_panel_widget.dart';
import 'widgets/floating_controls_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Initialize the app
    context.read<HomeCubit>().initialize();

    // Setup search listeners
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<HomeCubit>().onSearchChanged(_searchController.text);
  }

  void _onFocusChanged() {
    context.read<HomeCubit>().onSearchFocusChanged(_searchFocusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<HomeCubit, HomeState>(
          listener: (context, state) {
            // Handle error states
            if (state.status == HomeStatus.error && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }

            // Update search controller when search is cleared programmatically
            if (state.searchQuery != _searchController.text) {
              _searchController.text = state.searchQuery;
            }

            // Move map to selected road center
            if (state.selectedRoad != null && state.selectedRoad!.centerLocation != null) {
              final center = LocationModel(
                latitude: state.selectedRoad!.centerLocation!.latitude,
                longitude: state.selectedRoad!.centerLocation!.longitude,
              ).toLatLng();
              _mapController.move(center, 15.0);
            }

            // Move map to user location on first load
            if (state.userLocation != null) {
              final userLatLng = LocationModel(
                latitude: state.userLocation!.latitude,
                longitude: state.userLocation!.longitude,
              ).toLatLng();
              _mapController.move(userLatLng, 17.0);
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                // Map
                MapWidget(
                  mapController: _mapController,
                  userLocation: state.userLocation,
                  roads: state.roads,
                  selectedRoad: state.selectedRoad,
                  showColoredSegments: state.showColoredSegments,
                  onTap: (location) => context.read<HomeCubit>().onMapTapped(location),
                ),

                // Search Bar
                SearchBarWidget(
                  query: state.searchQuery,
                  hasFocus: _searchFocusNode.hasFocus,
                  focusNode: _searchFocusNode,
                  controller: _searchController,
                  onClear: () => context.read<HomeCubit>().clearSearch(),
                  onChanged: (query) => context.read<HomeCubit>().onSearchChanged(query),
                  onSubmitted: (query) {
                    if (state.searchResults.isNotEmpty) {
                      context.read<HomeCubit>().selectRoad(state.searchResults.first);
                      _searchFocusNode.unfocus();
                    }
                  },
                ),

                // Search Suggestions
                SearchSuggestionsWidget(
                  suggestions: state.searchResults,
                  isVisible: state.showSearchSuggestions,
                  onSuggestionTap: (road) {
                    context.read<HomeCubit>().selectRoad(road);
                    _searchController.text = road.name;
                    _searchFocusNode.unfocus();
                  },
                ),

                // Road Info Panel
                if (state.selectedRoad != null)
                  RoadInfoPanelWidget(
                    road: state.selectedRoad!,
                    isExpanded: state.isPanelExpanded,
                    onAddRide: () => _showDatePicker(context),
                    onDeleteRide: (date) => context.read<HomeCubit>().deleteRideDate(date),
                    onDeselect: () => context.read<HomeCubit>().selectRoad(null),
                  ),

                // Floating Controls
                FloatingControlsWidget(
                  selectedRoad: state.selectedRoad,
                  isPanelExpanded: state.isPanelExpanded,
                  showColoredSegments: state.showColoredSegments,
                  onTogglePanel: () => context.read<HomeCubit>().togglePanel(),
                  onCenterLocation: _centerOnUserLocation,
                  onToggleSegments: () => context.read<HomeCubit>().toggleColoredSegments(),
                ),

                // Loading indicator
                if (state.status == HomeStatus.loading || state.status == HomeStatus.loadingRoads)
                  const Center(child: LoadingIndicator()),
              ],
            );
          },
        ),
      ),
    );
  }

  void _centerOnUserLocation() {
    final state = context.read<HomeCubit>().state;
    if (state.userLocation != null) {
      final userLatLng = LocationModel(
        latitude: state.userLocation!.latitude,
        longitude: state.userLocation!.longitude,
      ).toLatLng();
      _mapController.move(userLatLng, 17.0);
    }
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale("fr", "FR"),
    );

    if (!context.mounted) return;

    if (date != null) {
      context.read<HomeCubit>().saveRideDate(date);
    }
  }
}
