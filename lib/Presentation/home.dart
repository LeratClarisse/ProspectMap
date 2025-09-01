// ignore_for_file: prefer_final_fields

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  LatLng? userLocation;
  late final StreamSubscription<Position> _positionStream;

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Coordinates for LaForet Audincourt
  LatLng _center = LatLng(47.4800, 6.8400);
  bool _hasInitialLocationSet = false;

  List<Map<String, dynamic>> _roadData = []; // Store raw road data
  List<Polyline> _selectedRoadSegments = [];
  int? _selectedRoadIndex;
  final String _noRoadSelectedString = "Aucune route sélectionnée";
  String _selectedRoadName = "";
  String _selectedRoadId = "";
  bool _isLoading = false;
  late Box<List<dynamic>> ridesBox; // New box to save rides per road
  bool _isPanelExpanded = false;
  bool _showColoredSegments = true;
  List<Polyline> _coloredRoadSegments = [];

  // Search related variables
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _showSuggestions = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _selectedRoadName = _noRoadSelectedString;
    _selectedRoadId = "";
    ridesBox = Hive.box<List<dynamic>>('rides');
    _startLiveLocation();
    _fetchRoads();

    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _updateSearchSuggestions();
    });
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      setState(() {
        _showSuggestions = _searchQuery.isNotEmpty;
      });
    } else {
      // Delay hiding suggestions to allow tap on suggestions
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }

  void _updateSearchSuggestions() {
    if (_searchQuery.isEmpty) {
      _searchSuggestions = [];
      _showSuggestions = false;
      return;
    }

    // Filter roads based on search query with better matching
    final query = _searchQuery.toLowerCase().trim();
    final filtered = _roadData.where((road) {
      final name = road['name'].toString().toLowerCase();
      return name.contains(query) || name.split(' ').any((word) => word.startsWith(query));
    }).toList();

    // Sort by relevance: exact matches first, then starts with, then contains
    filtered.sort((a, b) {
      final nameA = a['name'].toString().toLowerCase();
      final nameB = b['name'].toString().toLowerCase();

      // Exact match
      if (nameA == query) return -1;
      if (nameB == query) return 1;

      // Starts with query
      if (nameA.startsWith(query) && !nameB.startsWith(query)) return -1;
      if (nameB.startsWith(query) && !nameA.startsWith(query)) return 1;

      // Contains query (already filtered above)
      return nameA.compareTo(nameB);
    });

    _searchSuggestions = filtered.take(5).toList(); // Limit to 5 suggestions
    _showSuggestions = _searchSuggestions.isNotEmpty && _searchFocusNode.hasFocus;
  }

  void _onSuggestionTap(Map<String, dynamic> road) {
    // Find the center point of the road
    LatLng? centerPoint = _calculateRoadCenter(road);

    if (centerPoint != null) {
      // Move map to the road location with smooth animation
      _mapController.move(centerPoint, 15.0);

      // Select the road
      int roadIndex = _roadData.indexOf(road);
      setState(() {
        _selectedRoadIndex = roadIndex;
        _selectedRoadName = road['name'];
        _selectedRoadId = road['idRoad'];
        _buildSelectedRoadSegments();

        // Update search UI
        _searchController.text = road['name'];
        _showSuggestions = false;
        _searchFocusNode.unfocus();
      });
    }
  }

  LatLng? _calculateRoadCenter(Map<String, dynamic> road) {
    List<LatLng> allPoints = [];

    // Collect all points from all segments
    for (var segment in road['segments']) {
      allPoints.addAll(segment['points'] as List<LatLng>);
    }

    if (allPoints.isEmpty) return null;

    // Calculate center point
    double totalLat = 0;
    double totalLng = 0;

    for (var point in allPoints) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(
      totalLat / allPoints.length,
      totalLng / allPoints.length,
    );
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = "";
      _searchSuggestions = [];
      _showSuggestions = false;
      _searchFocusNode.unfocus();

      // Also deselect current road if any
      if (_selectedRoadIndex != null) {
        _selectedRoadIndex = null;
        _selectedRoadSegments = [];
        _selectedRoadName = _noRoadSelectedString;
        _selectedRoadId = "";
        _isPanelExpanded = false;
      }
    });
  }

  void _startLiveLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      // Checks a second time
      final newPermission = await Geolocator.requestPermission();
      if (newPermission == LocationPermission.denied || newPermission == LocationPermission.deniedForever) {
        // If permission is still denied, we can't get location
        return;
      }
    }

    // Get initial position immediately
    Position initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    setState(() {
      userLocation = LatLng(initialPosition.latitude, initialPosition.longitude);
      _center = userLocation!;

      // Move map to user location on first load
      if (!_hasInitialLocationSet) {
        _mapController.move(_center, 13.0);
        _hasInitialLocationSet = true;
      }
    });

    // Then start listening for location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Only update when user moves 10 meters
      ),
    ).listen((position) {
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);

        // Only update center for the first location fix
        if (!_hasInitialLocationSet) {
          _center = userLocation!;
          _mapController.move(_center, 17.0);
          _hasInitialLocationSet = true;
        }
      });
    });
  }

  void _buildColoredRoadSegments() {
    _coloredRoadSegments.clear();

    for (var road in _roadData) {
      final roadId = road['idRoad'];
      final rideDates = ridesBox.get(roadId, defaultValue: []) ?? [];
      if (rideDates.isNotEmpty) {
        // Road has at least one ride, add its colored segments
        final color = getColorBasedOnLastRideDate(roadId);
        for (var segment in road['segments']) {
          _coloredRoadSegments.add(
            Polyline(
              points: segment['points'],
              strokeWidth: 3.0,
              color: color.withValues(alpha: 0.7),
              borderColor: Colors.black,
              borderStrokeWidth: 0.3,
            ),
          );
        }
      }
    }
  }

  Color getColorBasedOnLastRideDate(String roadId) {
    final List<dynamic> rideDates = ridesBox.get(roadId, defaultValue: []) ?? [];
    if (rideDates.isEmpty) {
      return Colors.red; // default color if no ride
    }
    rideDates.sort(); // make sure dates are sorted
    final lastRideDate = DateTime.parse(rideDates.last);
    final daysSince = DateTime.now().difference(lastRideDate).inDays;

    if (daysSince <= 30) {
      return Colors.green;
    } else if (daysSince <= 45) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Future<void> _saveRideDate() async {
    if (_selectedRoadIndex == null) return;

    final String roadId = _roadData[_selectedRoadIndex!]['idRoad'];

    // Open a date picker
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        locale: Locale("fr", "FR"));

    if (pickedDate == null) {
      return; // User canceled
    }

    List<dynamic> existingDates = ridesBox.get(roadId, defaultValue: []) ?? [];

    existingDates.add(pickedDate.toIso8601String());

    ridesBox.put(roadId, existingDates);

    setState(() {
      _updateSelectedRoadColor();
      _buildColoredRoadSegments();
    });
  }

  void _confirmDeleteDate(BuildContext context, String date) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprime la date'),
        content: Text('Voulez-vous supprimer la date de passage $date ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        final List<dynamic> rideDates = ridesBox.get(_selectedRoadId, defaultValue: []) ?? [];
        rideDates.removeWhere((d) => d.startsWith(date)); // Remove by date match
        ridesBox.put(_selectedRoadId, rideDates);

        _updateSelectedRoadColor();
        _buildColoredRoadSegments();
      });
    }
  }

  // Function to fetch roads using saved geojson
  Future<void> _fetchRoads() async {
    setState(() {
      _isLoading = true;
      _roadData = [];
    });

    try {
      // GeoJSON file from https://overpass-turbo.eu/
      final geoJsonString =
          await DefaultAssetBundle.of(context).loadString('assets/geojsons/doubs_belfort_hautesaone_roads.geojson');
      final geoJson = json.decode(geoJsonString);

      Map<String, List<List<Map<String, dynamic>>>> roadGroups = {};

      for (var feature in geoJson['features']) {
        final geometry = feature['geometry'];
        final properties = feature['properties'];
        final name = properties['name'];

        if (geometry['type'] == 'LineString' && name != null) {
          List<LatLng> points = [];
          for (var coord in geometry['coordinates']) {
            points.add(LatLng(coord[1], coord[0])); // GeoJSON is [lon, lat]
          }

          // Initialize road name group if needed
          roadGroups.putIfAbsent(name, () => []);

          bool added = false;
          for (var group in roadGroups[name]!) {
            if (_areSegmentsConnected(group, points)) {
              group.add({'points': points, 'id': properties['@id']});
              added = true;
              break;
            }
          }

          if (!added) {
            roadGroups[name]!.add([
              {'points': points, 'id': properties['@id']}
            ]);
          }
        }
      }

      List<Map<String, dynamic>> consolidatedRoads = [];

      roadGroups.forEach((name, groups) {
        for (var group in groups) {
          final idRoad = group[0]['id'];
          final segments = group.map((segment) {
            final newSegment = Map.of(segment);
            newSegment.remove("id");
            return newSegment;
          }).toList();
          consolidatedRoads.add({'name': name, 'segments': segments, 'idRoad': idRoad});
        }
      });

      setState(() {
        _roadData = consolidatedRoads;
        _isLoading = false;
      });

      _buildColoredRoadSegments();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _areSegmentsConnected(List<Map<String, dynamic>> group, List<LatLng> newSegment) {
    for (var segment in group) {
      List<LatLng> existingPoints = segment['points'];

      // Check if the new segment shares a start or end point with any existing segment
      if (existingPoints.first == newSegment.first ||
          existingPoints.first == newSegment.last ||
          existingPoints.last == newSegment.first ||
          existingPoints.last == newSegment.last) {
        return true;
      }
    }
    return false;
  }

  void _buildSelectedRoadSegments() {
    if (_selectedRoadIndex != null) {
      final selectedRoad = _roadData[_selectedRoadIndex!];
      _selectedRoadSegments = selectedRoad['segments'].map<Polyline>((segment) {
        return Polyline(
          points: segment['points'],
          strokeWidth: 4.0,
          color: getColorBasedOnLastRideDate(_selectedRoadId),
          borderColor: Colors.black,
          borderStrokeWidth: 0.5,
        );
      }).toList();
    }
  }

  void _updateSelectedRoadColor() {
    _buildSelectedRoadSegments();
  }

  // Handle tap on map
  void _handleTap(TapPosition tapPosition, LatLng point) {
    // Hide search suggestions if showing
    if (_showSuggestions) {
      setState(() {
        _showSuggestions = false;
        _searchFocusNode.unfocus();
      });
      return;
    }

    // Check if tap is near any road
    double closestDistance = double.infinity;
    int closestRoadIndex = -1;

    // First pass: find the closest road to the tap
    for (int i = 0; i < _roadData.length; i++) {
      final road = _roadData[i];
      double minDistance = double.infinity;

      // Check each segment to find the closest point on this road
      for (var segment in road['segments']) {
        double segmentDistance = _findMinDistanceToSegment(point, segment['points']);
        if (segmentDistance < minDistance) {
          minDistance = segmentDistance;
        }
      }

      // If this road is closer than any we've seen so far, remember it
      if (minDistance < closestDistance) {
        closestDistance = minDistance;
        closestRoadIndex = i;
      }
    }

    // Use a threshold to determine if we actually selected a road
    final distanceThreshold = 0.0002; // Adjust this value as needed

    if (closestRoadIndex >= 0 && closestDistance < distanceThreshold) {
      if (_selectedRoadIndex == closestRoadIndex) {
        // Tapped the same selected road -> deselect
        setState(() {
          _selectedRoadIndex = null;
          _selectedRoadSegments = [];
          _selectedRoadName = _noRoadSelectedString;
          _selectedRoadId = "";
          _isPanelExpanded = false;
        });
      } else {
        // Select new road
        setState(() {
          _selectedRoadIndex = closestRoadIndex;
          _selectedRoadName = _roadData[closestRoadIndex]['name'];
          _selectedRoadId = _roadData[closestRoadIndex]['idRoad'];
          _buildSelectedRoadSegments();
        });
      }
    } else {
      // Tap outside any road -> deselect
      setState(() {
        _selectedRoadIndex = null;
        _selectedRoadSegments = [];
        _selectedRoadName = _noRoadSelectedString;
        _selectedRoadId = "";
        _isPanelExpanded = false;
      });
    }
  }

  // Helper method to find minimum distance to a polyline segment
  double _findMinDistanceToSegment(LatLng point, List<LatLng> polyline) {
    double minDist = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      double dist = _distanceToLine(point, polyline[i], polyline[i + 1]);
      if (dist < minDist) {
        minDist = dist;
      }
    }

    return minDist;
  }

  // Calculate distance from a point to a line segment
  double _distanceToLine(LatLng point, LatLng lineStart, LatLng lineEnd) {
    // Convert to radians for accurate distance calculation
    double lat = point.latitude * (pi / 180);
    double lng = point.longitude * (pi / 180);
    double lat1 = lineStart.latitude * (pi / 180);
    double lng1 = lineStart.longitude * (pi / 180);
    double lat2 = lineEnd.latitude * (pi / 180);
    double lng2 = lineEnd.longitude * (pi / 180);

    // Calculate distances
    double A = lat - lat1;
    double B = lng - lng1;
    double C = lat2 - lat1;
    double D = lng2 - lng1;

    double dot = A * C + B * D;
    double lenSq = C * C + D * D;
    double param = lenSq != 0 ? dot / lenSq : -1;

    double xx, yy;

    if (param < 0 || (lat1 == lat2 && lng1 == lng2)) {
      xx = lat1;
      yy = lng1;
    } else if (param > 1) {
      xx = lat2;
      yy = lng2;
    } else {
      xx = lat1 + param * C;
      yy = lng1 + param * D;
    }

    // Calculate squared distance
    double dx = lat - xx;
    double dy = lng - yy;

    return dx * dx + dy * dy;
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Rechercher une route...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(14),
            child: Icon(
              Icons.search,
              color: _searchQuery.isNotEmpty ? Theme.of(context).primaryColor : Colors.grey[500],
              size: 24,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        onSubmitted: (value) {
          if (_searchSuggestions.isNotEmpty) {
            _onSuggestionTap(_searchSuggestions.first);
          }
        },
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    if (!_showSuggestions || _searchSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 76, // Position below the search bar
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _searchSuggestions.length,
            itemBuilder: (context, index) {
              final road = _searchSuggestions[index];
              final rideDates = ridesBox.get(road['idRoad'], defaultValue: []) ?? [];
              final hasRides = rideDates.isNotEmpty;
              final lastRideText = hasRides ? _getLastRideText(road['idRoad']) : 'Jamais parcouru';

              return InkWell(
                onTap: () => _onSuggestionTap(road),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: index != _searchSuggestions.length - 1 ? Border(bottom: BorderSide(color: Colors.grey[200]!)) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.route, color: getColorBasedOnLastRideDate(road['idRoad']), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              road['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lastRideText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getLastRideText(String roadId) {
    final List<dynamic> rideDates = ridesBox.get(roadId, defaultValue: []) ?? [];
    if (rideDates.isEmpty) return 'Jamais parcouru';

    rideDates.sort();
    final lastRideDate = DateTime.parse(rideDates.last);
    final daysSince = DateTime.now().difference(lastRideDate).inDays;

    if (daysSince == 0) {
      return 'Parcouru aujourd\'hui';
    } else if (daysSince == 1) {
      return 'Parcouru hier';
    } else if (daysSince <= 7) {
      return 'Parcouru il y a $daysSince jours';
    } else if (daysSince <= 30) {
      return 'Parcouru il y a ${(daysSince / 7).round()} semaines';
    } else {
      return 'Parcouru il y a ${(daysSince / 30).round()} mois';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 13.0,
                onTap: _handleTap,
                minZoom: 10.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                  enableMultiFingerGestureRace: true,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                  tileProvider: NetworkTileProvider(
                    headers: {
                      'User-Agent': 'ProspectMap-App/1.0',
                    },
                  ),
                  keepBuffer: 2,
                ),
                if (userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                if (_showColoredSegments) PolylineLayer(polylines: _coloredRoadSegments),
                if (_selectedRoadSegments.isNotEmpty) PolylineLayer(polylines: _selectedRoadSegments),
              ],
            ),
            // Search Bar
            _buildSearchBar(),
            // Search Suggestions - positioned below search bar
            _buildSearchSuggestions(),
            if (_isPanelExpanded)
              Positioned(
                left: 20,
                right: 80,
                bottom: 80,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedRoadName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _selectedRoadIndex != null ? _saveRideDate : null,
                        child: const Text('Ajouter une date de passage'),
                      ),
                      const SizedBox(height: 8),
                      if ((ridesBox.get(_selectedRoadId, defaultValue: []) ?? []).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dates de passage :',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 110),
                                child: Builder(builder: (context) {
                                  final dates = List<String>.from(
                                    ridesBox.get(_selectedRoadId, defaultValue: []) ?? [],
                                  );
                                  // Sort descending (most recent first)
                                  dates.sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));
                                  return ListView(
                                    shrinkWrap: true,
                                    children: dates.map<Widget>((date) {
                                      final d = DateTime.parse(date);
                                      final formattedDate = d.toLocal().toString().split(' ')[0];
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(formattedDate, style: const TextStyle(fontSize: 14)),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              _confirmDeleteDate(context, formattedDate);
                                            },
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedRoadIndex = null;
                            _selectedRoadSegments = [];
                            _selectedRoadName = _noRoadSelectedString;
                            _selectedRoadId = "";
                            _isPanelExpanded = false;
                          });
                        },
                        child: const Text('Désélectionner'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_selectedRoadIndex != null) ...[
              // INFO button + Road Name Bubble
              Positioned(
                bottom: 80, // slightly above the location button
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  heroTag: 'info_button',
                  onPressed: () {
                    setState(() {
                      _isPanelExpanded = !_isPanelExpanded;
                    });
                  },
                  child: Icon(_isPanelExpanded ? Icons.close : Icons.info_outline),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 240),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _roadData[_selectedRoadIndex!]['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'center_location',
                mini: true,
                onPressed: () {
                  if (userLocation != null) {
                    _mapController.move(userLocation!, 17.0);
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 16,
              child: Switch(
                value: _showColoredSegments,
                onChanged: (value) {
                  setState(() {
                    _showColoredSegments = value;
                  });
                },
              ),
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
