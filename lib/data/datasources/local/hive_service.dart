import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _ridesBoxName = 'rides';
  static const String _settingsBoxName = 'settings';
  static const String _roadsBoxName = 'roads_cache';

  Box<List<dynamic>>? _ridesBox;
  Box? _settingsBox;
  Box? _roadsBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();

    _ridesBox = await Hive.openBox<List<dynamic>>(_ridesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _roadsBox = await Hive.openBox(_roadsBoxName);
  }

  /// Get rides box
  Box<List<dynamic>> get ridesBox {
    if (_ridesBox == null || !_ridesBox!.isOpen) {
      throw StateError('Rides box not initialized. Call init() first.');
    }
    return _ridesBox!;
  }

  /// Get settings box
  Box get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw StateError('Settings box not initialized. Call init() first.');
    }
    return _settingsBox!;
  }

  /// Get roads cache box
  Box get roadsBox {
    if (_roadsBox == null || !_roadsBox!.isOpen) {
      throw StateError('Roads box not initialized. Call init() first.');
    }
    return _roadsBox!;
  }

  /// Close all boxes
  Future<void> close() async {
    await _ridesBox?.close();
    await _settingsBox?.close();
    await _roadsBox?.close();
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAll() async {
    await _ridesBox?.clear();
    await _settingsBox?.clear();
    await _roadsBox?.clear();
  }

  /// Get ride dates for a road
  List<String> getRideDatesForRoad(String roadId) {
    final rides = ridesBox.get(roadId, defaultValue: []) ?? [];
    return List<String>.from(rides);
  }

  /// Save ride date for a road
  Future<void> saveRideForRoad(String roadId, String dateIso) async {
    final existingRides = getRideDatesForRoad(roadId);
    existingRides.add(dateIso);
    await ridesBox.put(roadId, existingRides);
  }

  /// Remove ride date for a road
  Future<void> removeRideForRoad(String roadId, String dateIso) async {
    final existingRides = getRideDatesForRoad(roadId);
    existingRides.removeWhere((date) => date.startsWith(dateIso.split('T')[0]));
    await ridesBox.put(roadId, existingRides);
  }

  /// Get all rides data
  Map<String, List<String>> getAllRides() {
    final Map<String, List<String>> allRides = {};

    for (final key in ridesBox.keys) {
      final rides = getRideDatesForRoad(key.toString());
      if (rides.isNotEmpty) {
        allRides[key.toString()] = rides;
      }
    }

    return allRides;
  }

  /// Settings methods
  bool getDarkMode() {
    return settingsBox.get('darkmode', defaultValue: false);
  }

  Future<void> setDarkMode(bool isDark) async {
    await settingsBox.put('darkmode', isDark);
  }

  bool getShowColoredSegments() {
    return settingsBox.get('show_colored_segments', defaultValue: true);
  }

  Future<void> setShowColoredSegments(bool show) async {
    await settingsBox.put('show_colored_segments', show);
  }

  /// Cache roads data
  Future<void> cacheRoads(List<Map<String, dynamic>> roads) async {
    await roadsBox.put('cached_roads', roads);
    await roadsBox.put('cache_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached roads
  List<Map<String, dynamic>>? getCachedRoads() {
    final roads = roadsBox.get('cached_roads');
    if (roads == null) return null;

    return List<Map<String, dynamic>>.from(roads);
  }

  /// Check if cache is valid (less than 24 hours old)
  bool isCacheValid() {
    final timestamp = roadsBox.get('cache_timestamp');
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    return difference.inHours < 24; // Cache valid for 24 hours
  }
}
