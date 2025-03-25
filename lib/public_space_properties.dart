import 'dart:convert';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PublicSpaceProperties {
  final String firestoreId;
  final String space_id;
  final String type;
  final String? name;
  final String? location;
  final Uri? url;
  final String? description;
  final List<String> details;
  final List<String> amenities;
  final List<String> equipment;

  // constructor to initialize the properties
  PublicSpaceProperties({
    required this.firestoreId,
    required this.space_id,
    required this.name,
    required this.type,
    required this.location,
    required this.url,
    required this.description,
    required this.details,
    required this.amenities,
    required this.equipment,
  });

  // optional: Add a toString method for easier debugging
  @override
  String toString() {
    return 'PublicSpaceProperties(name: $name, type: $type)';
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
        description: json['properties']['description'], // Parse the URL
details: json['properties']['details'] != null
    ? List<String>.from(jsonDecode(json['properties']['details']))
    : [],
amenities: json['properties']['amenities'] != null
    ? List<String>.from(jsonDecode(json['properties']['amenities']))
    : [],
equipment: json['properties']['equipment'] != null
    ? List<String>.from(jsonDecode(json['properties']['equipment']))
    : [],
      ),
    );
  }

  // Optional: Add a toString method for easier debugging
  @override
  String toString() {
    return 'PublicSpaceFeature(type: $type, geometry: $geometry, properties: $properties)';
  }
}
