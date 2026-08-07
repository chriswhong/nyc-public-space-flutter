import 'dart:convert';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PublicSpaceProperties {
  final String firestoreId;
  final String? space_id;
  final String type;
  final String? name;
  final String? location;
  final Uri? url;
  final String? description;
  final List<String> details;
  final List<String> amenities;
  final List<String> equipment;
  final Map<String, Map<String, int>> amenitySurvey;

  // constructor to initialize the properties
  PublicSpaceProperties({
    required this.firestoreId,
    this.space_id,
    required this.name,
    required this.type,
    required this.location,
    required this.url,
    required this.description,
    required this.details,
    required this.amenities,
    required this.equipment,
    this.amenitySurvey = const {},
  });

  bool get isTemporarilyClosed => details.contains('temporarily_closed');

  // optional: Add a toString method for easier debugging
  @override
  String toString() {
    return 'PublicSpaceProperties(name: $name, type: $type)';
  }

  Map<String, dynamic> toMap() {
    return {
      'firestoreId': firestoreId,
      'space_id': space_id,
      'name': name,
      'type': type,
      'location': location,
      'url': url?.toString(),
      'description': description,
      'details': details,
      'amenities': amenities,
      'equipment': equipment
    };
  }
}

// GeoJSON Feature class
class PublicSpaceFeature {
  final String type; // Usually "Feature" in GeoJSON
  final Point geometry; // The geometry (e.g., Point in this case)
  final PublicSpaceProperties properties; // Custom properties of the feature

  // Constructor
  PublicSpaceFeature({
    required this.type,
    required this.geometry,
    required this.properties,
  });

  // Convert to a GeoJSON-compatible map (to be serialized to JSON)
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'geometry': geometry.toJson(),
      'properties': {
        'firestoreId': properties.firestoreId,
        'space_id': properties.space_id,
        'name': properties.name,
        'type': properties.type,
        'location': properties.location,
        'url': properties.url,
        'description': properties.description,
        'details': properties.details,
        'amenities': properties.amenities,
        'equipment': properties.equipment,
      },
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'geometry': geometry.toJson(),
      'properties': properties.toMap(),
    };
  }

  // Factory constructor to create PublicSpaceFeature from JSON
  factory PublicSpaceFeature.fromJson(Map<String, dynamic> json) {
    return PublicSpaceFeature(
      type: json['type'],
      geometry: Point.fromJson(json['geometry']),
      properties: PublicSpaceProperties(
        firestoreId: json['properties']['firestoreId'],
        space_id: json['properties']['space_id'],
        name: json['properties']['name'],
        type: json['properties']['type'],
        location: json['properties']['location'],
        url: json['properties']['url'] != null &&
                json['properties']['url'].isNotEmpty
            ? Uri.parse(json['properties']['url'])
            : null,
        description: json['properties']['description'],
details: json['properties']['details'] != null
    ? (json['properties']['details'] is String
        ? List<String>.from(jsonDecode(json['properties']['details']))
        : List<String>.from(json['properties']['details']))
    : [],
amenities: json['properties']['amenities'] != null
    ? (json['properties']['amenities'] is String
        ? List<String>.from(jsonDecode(json['properties']['amenities']))
        : List<String>.from(json['properties']['amenities']))
    : [],
equipment: json['properties']['equipment'] != null
    ? (json['properties']['equipment'] is String
        ? List<String>.from(jsonDecode(json['properties']['equipment']))
        : List<String>.from(json['properties']['equipment']))
    : [],
amenitySurvey: _parseAmenitySurvey(json['properties']['amenity_survey']),
      ),
    );
  }

  // Optional: Add a toString method for easier debugging
  @override
  String toString() {
    return 'PublicSpaceFeature(type: $type, geometry: $geometry, properties: $properties)';
  }
}

Map<String, Map<String, int>> _parseAmenitySurvey(dynamic raw) {
  if (raw == null) return {};
  if (raw is String) {
    try {
      raw = jsonDecode(raw);
    } catch (_) {
      return {};
    }
  }
  if (raw is! Map) return {};
  return (raw as Map<dynamic, dynamic>).map((k, v) =>
      MapEntry(k as String, Map<String, int>.from(v as Map)));
}
