import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:nyc_public_space_map/colors.dart';

class FloatingLocatorButton extends StatelessWidget {
  final MapboxMap? mapboxMap;

  const FloatingLocatorButton({super.key, this.mapboxMap});

  _handlePress() async {
    // Get the current position
    var position = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );

    mapboxMap?.flyTo(
        CameraOptions(
            zoom: 14,
            center: Point(
                coordinates: Position(position.longitude, position.latitude))),
        null);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed:
          _handlePress, // Executes the passed function or defaults to doing nothing
      backgroundColor: Colors.white,
      shape: const CircleBorder(),
      // mini: true,
      child: Transform.translate(
        offset: const Offset(-1, 1),
        child: const FaIcon(
          FontAwesomeIcons.locationArrow,
          color: AppColors.gray,
          size: 20.0,
        ),
      ),
    );
  }
}
