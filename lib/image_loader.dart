import 'dart:typed_data';
import 'package:flutter/services.dart';

// Singleton class to handle image loading and caching
class ImageLoader {
  // Private constructor for singleton pattern
  ImageLoader._privateConstructor();

  // Single instance of ImageLoader
  static final ImageLoader instance = ImageLoader._privateConstructor();

  // Future to handle image loading and caching
  late Future<void> images;

  // Variables to hold the loaded images
  late Uint8List parkImage;
  late Uint8List wpaaImage;
  late Uint8List popsImage;
  late Uint8List plazaImage;

  // Method to load images
  Future<void> loadImages() async {
    images = Future.wait([
      _loadImage('assets/park.png').then((image) => parkImage = image),
      _loadImage('assets/wpaa.png').then((image) => wpaaImage = image),
      _loadImage('assets/pops.png').then((image) => popsImage = image),
      _loadImage('assets/plaza.png').then((image) => plazaImage = image),
    ]);
  }

  // Helper method to load an individual image
  Future<Uint8List> _loadImage(String assetPath) async {
    final ByteData byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List();
  }
}