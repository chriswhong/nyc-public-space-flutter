import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  String? get borough {
    if (lat >= 40.4774 && lat <= 40.6501 && lng >= -74.2591 && lng <= -74.0341) return 'Staten Island';
    if (lat >= 40.6999 && lat <= 40.8816 && lng >= -74.0479 && lng <= -73.9067) return 'Manhattan';
    if (lat >= 40.7855 && lat <= 40.9176 && lng >= -73.9339 && lng <= -73.7654) return 'Bronx';
    if (lat >= 40.5707 && lat <= 40.7395 && lng >= -74.0421 && lng <= -73.8333) return 'Brooklyn';
    if (lat >= 40.5431 && lat <= 40.8007 && lng >= -73.9625 && lng <= -73.7004) return 'Queens';
    return null;
  }

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
  List<FavoriteItem> _favorites = [];

  List<FavoriteItem> get favorites => List.unmodifiable(_favorites);
  List<String> get favoriteIds =>
      _favorites.map((f) => f.firestoreId).toList();

  bool isFavorite(String firestoreId) =>
      _favorites.any((f) => f.firestoreId == firestoreId);

  CollectionReference<Map<String, dynamic>>? _favoritesCollection(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites');

  void initialize() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _load(user.uid);
      } else {
        _favorites = [];
        notifyListeners();
      }
    });
  }

  Future<void> _load(String uid) async {
    final snapshot = await _favoritesCollection(uid)!.get();
    _favorites = snapshot.docs
        .map((doc) => FavoriteItem.fromJson(doc.data()))
        .toList();
    notifyListeners();
  }

  Future<void> toggle(PublicSpaceFeature feature) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final id = feature.properties.firestoreId;
    if (isFavorite(id)) {
      _favorites.removeWhere((f) => f.firestoreId == id);
      notifyListeners();
      await _favoritesCollection(user.uid)!.doc(id).delete();
    } else {
      final item = FavoriteItem.fromFeature(feature);
      _favorites.add(item);
      notifyListeners();
      await _favoritesCollection(user.uid)!.doc(id).set(item.toJson());
    }
  }

  Future<void> remove(String firestoreId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _favorites.removeWhere((f) => f.firestoreId == firestoreId);
    notifyListeners();
    await _favoritesCollection(user.uid)!.doc(firestoreId).delete();
  }
}
