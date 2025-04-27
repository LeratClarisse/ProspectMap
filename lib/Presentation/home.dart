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

  List<Map<String, dynamic>> _roadData = []; // Store raw road data
  List<Polyline> _selectedRoadSegments = [];
  int? _selectedRoadIndex;
  final String _noRoadSelectedString = "Aucune route sélectionnée";
  String _selectedRoadName = "";
  bool _isLoading = false;
  late Box<List<dynamic>> ridesBox; // New box to save rides per road

  @override
  void initState() {
    _selectedRoadName = _noRoadSelectedString;
    super.initState();
    ridesBox = Hive.box<List<dynamic>>('rides');
    _fetchRoads();
  }

  Color getColorBasedOnLastRideDate(String roadName) {
    final List<dynamic> rideDates = ridesBox.get(roadName, defaultValue: []) ?? [];
    if (rideDates.isEmpty) {
      return Colors.red; // default color if no ride
    }
    rideDates.sort(); // make sure dates are sorted
    final lastRideDate = DateTime.parse(rideDates.last);
    final daysSince = DateTime.now().difference(lastRideDate).inDays;

    if (daysSince <= 30) {
      return Colors.green;
    } else if (daysSince <= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
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

    setState(() {
      _updateSelectedRoadColor();
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
        final List<dynamic> rideDates = ridesBox.get(_selectedRoadName, defaultValue: []) ?? [];
        rideDates.removeWhere((d) => d.startsWith(date)); // Remove by date match
        ridesBox.put(_selectedRoadName, rideDates);

        _updateSelectedRoadColor();
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

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: overpassQuery,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

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
      } else {
        setState(() {
          _isLoading = false;
        });
      }
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
          color: getColorBasedOnLastRideDate(_selectedRoadName),
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
// Handle tap on map
  void _handleTap(TapPosition tapPosition, LatLng point) {
    // Don't select a road if we tap near the UI elements at the bottom
    if (point.latitude < south + 0.003) {
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
      setState(() {
        _selectedRoadIndex = closestRoadIndex;
        _selectedRoadName = _roadData[closestRoadIndex]['name'];
        _buildSelectedRoadSegments();
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Prospect Map'),
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
                    'User-Agent': 'ProspectMap-App/1.0',
                  },
                ),
                keepBuffer: 2,
              ),
              // Show all segments of the selected road
              if (_selectedRoadSegments.isNotEmpty) PolylineLayer(polylines: _selectedRoadSegments)
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
                  Text(
                    _selectedRoadName,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _selectedRoadIndex != null ? _saveRideDate : null,
                    child: const Text('Ajouter une date de passage'),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedRoadName != _noRoadSelectedString)
                    Builder(
                      builder: (context) {
                        final List<dynamic> rideDates = ridesBox.get(_selectedRoadName, defaultValue: []) ?? [];
                        if (rideDates.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dates de passage :', style: TextStyle(fontWeight: FontWeight.bold)),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 110),
                                child: ListView(
                                  shrinkWrap: true,
                                  children: (rideDates..sort((a, b) => b.compareTo(a))).map((date) {
                                    final d = DateTime.parse(date);
                                    final formattedDate = d.toLocal().toString().split(' ')[0];
                                    return Row(
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
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedRoadIndex = null;
                        _selectedRoadSegments = [];
                        _selectedRoadName = _noRoadSelectedString;
                      });
                    },
                    child: const Text('Désélectionner'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
