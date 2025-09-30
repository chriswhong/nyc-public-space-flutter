// gets the full geojson of public spaces from firebase via a cloud function
// this powers local search, but could be used to populate the map instead of a tileset
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'public_space_properties.dart';

class GeoJsonProvider with ChangeNotifier {
  List<PublicSpaceFeature> _features = [];

  List<PublicSpaceFeature> get features => _features;

  Future<void> fetchGeoJson() async {
    final url = Uri.parse('https://getdatasetasgeojson-vs6e5w5f2a-uc.a.run.app/');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _features = (data['features'] as List)
          .map((f) => PublicSpaceFeature.fromJson(f as Map<String, dynamic>))
          .toList();
      print('GeoJSON fetched successfully. Features loaded: ${_features.length}');
      notifyListeners();
    } else {
      print('Failed to fetch GeoJSON: ${response.statusCode} ${response.body}');
    }
  }
}
