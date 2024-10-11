import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PublicSpaceProperties {
  final String type;
  final String? name;
  final String? location;
  final Uri? url;

  // constructor to initialize the properties
  PublicSpaceProperties({required this.name, required this.type, required this.location, required this.url});

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
        'location': properties.location,
        'url': properties.url,
      },
    };
  }

  // Factory constructor to create PublicSpaceFeature from JSON
  factory PublicSpaceFeature.fromJson(Map<String, dynamic> json) {
    return PublicSpaceFeature(
      type: json['type'],
      geometry: Point.fromJson(json['geometry']),
      properties: PublicSpaceProperties(
        name: json['properties']['name'],
        type: json['properties']['type'],
        location: json['properties']['location'],
        url: json['properties']['url'] != null ? Uri.parse(json['properties']['url']) : null,  // Parse the URL
      ),
    );
  }

  // Optional: Add a toString method for easier debugging
  @override
  String toString() {
    return 'PublicSpaceFeature(type: $type, geometry: $geometry, properties: $properties)';
  }
}
