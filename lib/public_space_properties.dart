class PublicSpaceProperties {
  final String name;
  final String type;

  // Constructor to initialize the properties
  PublicSpaceProperties({required this.name, required this.type});

  // Optional: Add a toString method for easier debugging
  @override
  String toString() {
    return 'PublicSpaceProperties(name: $name, type: $type)';
  }
}