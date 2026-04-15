import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'public_space_properties.dart';

class FavoriteItem {
  final String firestoreId;
  final String name;
  final String type;
  final double lat;
  final double lng;

  const FavoriteItem({
    required this.firestoreId,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
  });

  factory FavoriteItem.fromFeature(PublicSpaceFeature feature) {
    return FavoriteItem(
      firestoreId: feature.properties.firestoreId,
      name: feature.properties.name ?? '',
      type: feature.properties.type,
      lat: feature.geometry.coordinates.lat.toDouble(),
      lng: feature.geometry.coordinates.lng.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'firestoreId': firestoreId,
        'name': name,
        'type': type,
        'lat': lat,
        'lng': lng,
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        firestoreId: json['firestoreId'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}

class FavoritesProvider extends ChangeNotifier {
  static const _prefsKey = 'favorites_v1';
  List<FavoriteItem> _favorites = [];

  List<FavoriteItem> get favorites => List.unmodifiable(_favorites);
  List<String> get favoriteIds =>
      _favorites.map((f) => f.firestoreId).toList();

  bool isFavorite(String firestoreId) =>
      _favorites.any((f) => f.firestoreId == firestoreId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      _favorites = list
          .map((e) => FavoriteItem.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  Future<void> toggle(PublicSpaceFeature feature) async {
    final id = feature.properties.firestoreId;
    if (isFavorite(id)) {
      _favorites.removeWhere((f) => f.firestoreId == id);
    } else {
      _favorites.add(FavoriteItem.fromFeature(feature));
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String firestoreId) async {
    _favorites.removeWhere((f) => f.firestoreId == firestoreId);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_favorites.map((f) => f.toJson()).toList()),
    );
  }
}
