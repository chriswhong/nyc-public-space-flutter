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