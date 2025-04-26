import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MapController _mapController = MapController();

  // Coordinates for Croix
  final LatLng _center = LatLng(47.4600, 6.9600);
  // Bounding box for Croix area
  final double north = 47.5100;
  final double south = 47.4100;
  final double east = 7.0300;
  final double west = 6.8900;

  final List<Marker> _markers = [];
  List<Map<String, dynamic>> _roadData = []; // Store raw road data
  List<Polyline> _selectedRoadSegments = [];
  int? _selectedRoadIndex;
  String _selectedRoadName = "No road selected";
  bool _isLoading = false;
  late Box<List<dynamic>> ridesBox; // New box to save rides per road

  @override
  void initState() {
    super.initState();
    ridesBox = Hive.box<List<dynamic>>('rides');
    _fetchRoads();
  }

  Future<void> _saveRideDate() async {
    if (_selectedRoadIndex == null) return;

    final String roadName = _roadData[_selectedRoadIndex!]['name'];

    // Open a date picker
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) {
      return; // User canceled
    }

    List<dynamic> existingDates = ridesBox.get(roadName, defaultValue: []) ?? [];

    // Add the picked date
    existingDates.add(pickedDate.toIso8601String());

    // Sort dates descending
    existingDates.sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    ridesBox.put(roadName, existingDates);

    setState(() {}); // Refresh UI
  }

  void _confirmDeleteDate(BuildContext context, String date) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ride Date'),
        content: Text('Are you sure you want to delete $date?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        final List<dynamic> rideDates = ridesBox.get(_selectedRoadName, defaultValue: []) ?? [];
        rideDates.removeWhere((d) => d.startsWith(date)); // Remove by date match
        ridesBox.put(_selectedRoadName, rideDates);
      });
    }
  }

  // Function to fetch roads using Overpass API
  Future<void> _fetchRoads() async {
    setState(() {
      _isLoading = true;
      _roadData = [];
    });

    try {
      String overpassQuery = """
    [out:json][timeout:30][maxsize:1073741824];
    way["highway"]["name"]
        ($south,$west,$north,$east);
    out geom;
    """;

      debugPrint('Fetching roads in area: $south,$west,$north,$east');

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: overpassQuery,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        debugPrint('Received ${data['elements'].length} elements from Overpass API');

        Map<String, List<List<Map<String, dynamic>>>> roadGroups = {};

        for (var element in data['elements']) {
          if (element['type'] == 'way' && element['geometry'] != null && element['geometry'].length > 1 && element['tags']?['name'] != null) {
            List<LatLng> points = [];
            for (var node in element['geometry']) {
              points.add(LatLng(node['lat'], node['lon']));
            }

            if (points.length >= 2) {
              String roadName = element['tags']['name'];

              // Initialize the list for this road name if it doesn't exist
              roadGroups.putIfAbsent(roadName, () => []);

              bool added = false;
              for (var group in roadGroups[roadName]!) {
                if (_areSegmentsConnected(group, points)) {
                  group.add({
                    'id': element['id'],
                    'points': points,
                    'tags': element['tags'] ?? {},
                  });
                  added = true;
                  break;
                }
              }

              // If no existing group was a match, create a new one
              if (!added) {
                roadGroups[roadName]!.add([
                  {
                    'id': element['id'],
                    'points': points,
                    'tags': element['tags'] ?? {},
                  }
                ]);
              }
            }
          }
        }

        // Flatten roadGroups into the final roadData structure
        List<Map<String, dynamic>> consolidatedRoads = [];

        roadGroups.forEach((roadName, groups) {
          for (var group in groups) {
            consolidatedRoads.add({
              'name': roadName,
              'segments': group,
            });
          }
        });

        setState(() {
          _roadData = consolidatedRoads;
          _isLoading = false;
        });

        debugPrint('Processed ${consolidatedRoads.length} unique grouped roads');
        for (var road in consolidatedRoads) {
          debugPrint('Road: ${road['name']} with ${road['segments'].length} segments');
        }
      } else {
        debugPrint('Error response from Overpass API: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching roads: $e');
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

  // Handle tap on map
// Handle tap on map
  void _handleTap(TapPosition tapPosition, LatLng point) {
    // Don't select a road if we tap near the UI elements at the bottom
    if (point.latitude < south + 0.003) {
      return;
    }

    // Check if tap is near any road
    bool roadTapped = false;
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
      final selectedRoad = _roadData[closestRoadIndex];
      debugPrint('Selected road: ${selectedRoad['name']} with distance: $closestDistance');

      setState(() {
        _selectedRoadIndex = closestRoadIndex;
        _selectedRoadName = selectedRoad['name'];

        // Create polylines for all segments of this road
        _selectedRoadSegments = selectedRoad['segments'].map<Polyline>((segment) {
          return Polyline(
            points: segment['points'],
            strokeWidth: 4.0,
            color: Colors.red,
            borderColor: Colors.black,
            borderStrokeWidth: 0.5,
          );
        }).toList();
      });
      roadTapped = true;
    } else {
      debugPrint(
          'No road selected. Closest road is ${closestRoadIndex >= 0 ? _roadData[closestRoadIndex]['name'] : 'none'} at distance $closestDistance');
    }

    // If no road was tapped and we're not clicking on UI elements
    if (!roadTapped) {
      setState(() {
        _markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: point,
            child: const Icon(Icons.location_on, color: Colors.red),
          ),
        );
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

    // Need to add import at the top: import 'dart:math' show pi;
    return dx * dx + dy * dy;
  }

  @override
  Widget build(BuildContext context) {
    Box settingsBox = Hive.box('settings');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Map of Croix'),
      ),
      body: Stack(
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
                    'User-Agent': 'Croix-Map-App/1.0',
                  },
                ),
                keepBuffer: 2,
              ),
              // Show all segments of the selected road
              if (_selectedRoadSegments.isNotEmpty) PolylineLayer(polylines: _selectedRoadSegments),
              MarkerLayer(markers: _markers),
              // Boundary rectangle
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: [
                      LatLng(south, west),
                      LatLng(south, east),
                      LatLng(north, east),
                      LatLng(north, west),
                    ],
                    color: Colors.transparent,
                    borderColor: Colors.red,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            ],
          ),
          // Info panel in the lower third of the screen
          Positioned(
            left: 20,
            right: 20,
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
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selected Road:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    _selectedRoadName,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _selectedRoadIndex != null ? _saveRideDate : null,
                    child: const Text('Save Ride Date'),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedRoadName != "No road selected")
                    Builder(
                      builder: (context) {
                        final List<dynamic> rideDates = ridesBox.get(_selectedRoadName, defaultValue: []) ?? [];
                        if (rideDates.isEmpty) {
                          return const Text('No rides yet.');
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ride Dates:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...rideDates.map((date) {
                              final d = DateTime.parse(date);
                              final formattedDate = d.toLocal().toString().split(' ')[0];
                              return GestureDetector(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          _confirmDeleteDate(context, formattedDate);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedRoadIndex = null;
                        _selectedRoadSegments = [];
                        _selectedRoadName = "No road selected";
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _mapController.move(_center, 15.0);
                  },
                  child: const Text('Reset View'),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<Box>(
                  valueListenable: settingsBox.listenable(),
                  builder: (context, box, widget) {
                    return Row(
                      children: [
                        Container(
                          color: Colors.white70,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: const Text('Dark Mode'),
                        ),
                        Switch(
                          value: box.get('darkmode', defaultValue: false),
                          onChanged: (val) {
                            settingsBox.put('darkmode', val);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
