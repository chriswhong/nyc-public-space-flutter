import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'public_space_properties.dart';

class VisitedItem {
  final String firestoreId;
  final String name;
  final String type;
  final double lat;
  final double lng;

  const VisitedItem({
    required this.firestoreId,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
  });

  factory VisitedItem.fromFeature(PublicSpaceFeature feature) {
    return VisitedItem(
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

  factory VisitedItem.fromJson(Map<String, dynamic> json) => VisitedItem(
        firestoreId: json['firestoreId'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}

class VisitedProvider extends ChangeNotifier {
  List<VisitedItem> _visited = [];

  List<VisitedItem> get visited => List.unmodifiable(_visited);
  List<String> get visitedIds => _visited.map((v) => v.firestoreId).toList();

  bool isVisited(String firestoreId) =>
      _visited.any((v) => v.firestoreId == firestoreId);

  CollectionReference<Map<String, dynamic>>? _visitedCollection(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('visited');

  void initialize() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _load(user.uid);
      } else {
        _visited = [];
        notifyListeners();
      }
    });
  }

  Future<void> _load(String uid) async {
    final snapshot = await _visitedCollection(uid)!.get();
    _visited = snapshot.docs
        .map((doc) => VisitedItem.fromJson(doc.data()))
        .toList();
    notifyListeners();
  }

  Future<void> toggle(PublicSpaceFeature feature) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final id = feature.properties.firestoreId;
    if (isVisited(id)) {
      _visited.removeWhere((v) => v.firestoreId == id);
      notifyListeners();
      await _visitedCollection(user.uid)!.doc(id).delete();
    } else {
      final item = VisitedItem.fromFeature(feature);
      _visited.add(item);
      notifyListeners();
      await _visitedCollection(user.uid)!.doc(id).set(item.toJson());
    }
  }
}
