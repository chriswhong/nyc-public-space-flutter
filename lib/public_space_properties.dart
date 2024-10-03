import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PublicSpaceProperties {
  final String name;
  final String type;

  // constructor to initialize the properties
  PublicSpaceProperties({required this.name, required this.type});

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
        'name': properties.name,
        'type': properties.type,
      },
    };
  }

  // Factory constructor to create PublicSpaceFeature from JSON
  factory PublicSpaceFeature.fromJson(Map<String, dynamic> json) {
    return PublicSpaceFeature(
      type: json['type'],
      geometry: Point.fromJson(json['geometry']),
      properties: PublicSpaceProperties(
        name: json['properties']['name'] ?? 'No Name Provided',
        type: json['properties']['type'],
      ),
    );
  }

  // Optional: Add a toString method for easier debugging
  @override
  String toString() {
    return 'PublicSpaceFeature(type: $type, geometry: $geometry, properties: $properties)';
  }
}
