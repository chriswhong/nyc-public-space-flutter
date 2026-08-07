import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'public_space_properties.dart';

const _cacheKey = 'geojson_cache';
const _cacheTimestampKey = 'geojson_cache_timestamp';
const _cacheTtl = Duration(hours: 8);

class GeoJsonProvider with ChangeNotifier {
  List<PublicSpaceFeature> _features = [];
  bool _loadFailed = false;

  List<PublicSpaceFeature> get features => _features;
  bool get loadFailed => _loadFailed;

  /// Loads from cache if fresh, otherwise fetches from network.
  Future<void> fetchGeoJson() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);
    final cachedTimestamp = prefs.getInt(_cacheTimestampKey);

    if (cachedJson != null && cachedTimestamp != null) {
      final age = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
      if (age < _cacheTtl.inMilliseconds) {
        _loadFromJson(cachedJson);
        return;
      }
    }

    await _fetchFromNetwork(prefs);
  }

  /// Forces a network fetch regardless of cache age (used on foreground resume).
  Future<void> refreshIfStale() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTimestamp = prefs.getInt(_cacheTimestampKey);

    if (cachedTimestamp != null) {
      final age = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
      if (age < _cacheTtl.inMilliseconds) return; // still fresh, skip
    }

    await _fetchFromNetwork(prefs);
  }

  void _loadFromJson(String rawJson) {
    final data = json.decode(rawJson);
    _features = (data['features'] as List)
        .map((f) => PublicSpaceFeature.fromJson(f as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> _fetchFromNetwork(SharedPreferences prefs) async {
    const url = 'https://getdatasetasgeojson-vs6e5w5f2a-uc.a.run.app/?slim=true';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await prefs.setString(_cacheKey, response.body);
        await prefs.setInt(_cacheTimestampKey,
            DateTime.now().millisecondsSinceEpoch);
        _loadFromJson(response.body);
        _loadFailed = false;
        return;
      }
    } catch (_) {}

    // Network failed or non-200 — fall back to stale cache if available
    final cachedJson = prefs.getString(_cacheKey);
    if (cachedJson != null && _features.isEmpty) {
      _loadFromJson(cachedJson);
    } else if (_features.isEmpty) {
      _loadFailed = true;
      notifyListeners();
    }
  }
}
