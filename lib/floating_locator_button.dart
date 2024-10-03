import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

class FloatingLocatorButton extends StatelessWidget {
  final MapboxMap? mapboxMap;

  FloatingLocatorButton({Key? key, this.mapboxMap}) : super(key: key);

  _handlePress() async {
    // Get the current position
    var position = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );

    mapboxMap?.flyTo(
        CameraOptions(
            center: Point(
                coordinates: Position(position.longitude, position.latitude))),
        null);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 120.0,
      right: 15,
      child: FloatingActionButton(
        onPressed:
            _handlePress, // Executes the passed function or defaults to doing nothing
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        mini: true,
        child: Transform.translate(
          offset: const Offset(-1, 1),
          child: const FaIcon(
            FontAwesomeIcons.locationArrow,
            color: Colors.blue,
            size: 20.0,
          ),
        ),
      ),
    );
  }
}
