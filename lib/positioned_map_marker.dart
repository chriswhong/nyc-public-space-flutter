import 'package:flutter/material.dart';

class PositionedMapMarker extends StatelessWidget {
  final String type;
  final double mapHeight;

  const PositionedMapMarker({
    super.key,
    required this.type,
    required this.mapHeight,
  });

  @override
  Widget build(BuildContext context) {
    final markerAsset = _markerAssetForType(type);

    return Positioned(
      bottom: mapHeight / 2,
      child: IgnorePointer(
        child: Image.asset(
          markerAsset,
          width: 40,
          height: 40,
        ),
      ),
    );
  }

  /// Map types to image assets
  String _markerAssetForType(String type) {
    switch (type) {
      case 'pops':
        return 'assets/pops.png';
      case 'park':
        return 'assets/park.png';
      case 'wpaa':
        return 'assets/wpaa.png';
      case 'plaza':
        return 'assets/plaza.png';
      case 'stp':
        return 'assets/stp.png';
      case 'misc':
      default:
        return 'assets/misc.png';
    }
  }
}
