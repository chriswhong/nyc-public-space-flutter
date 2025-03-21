import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

const double mapHeight = 230;

class DraggableMapboxMarker extends StatefulWidget {
  final Point initialPoint;
  final void Function() onCancel;
  final void Function(Point) onLocationChanged;

  const DraggableMapboxMarker({
    super.key,
    required this.initialPoint,
    required this.onCancel,
    required this.onLocationChanged,
  });

  @override
  State<DraggableMapboxMarker> createState() => _DraggableMapboxMarkerState();
}

class _DraggableMapboxMarkerState extends State<DraggableMapboxMarker> {
  late MapboxMap _mapboxMap;
  late Point _initialPoint;
  Point? _currentCenter;

  @override
  void initState() {
    super.initState();
    _initialPoint = widget.initialPoint;
    _currentCenter = _initialPoint;
  }

  Future<void> _resetMapCamera() async {
    await _mapboxMap.setCamera(CameraOptions(center: _initialPoint));
    setState(() {
      _currentCenter = _initialPoint;
    });
  }

  bool _hasChanged() {
    if (_currentCenter == null) return false;
    return _currentCenter!.coordinates.lat != _initialPoint.coordinates.lat ||
        _currentCenter!.coordinates.lng != _initialPoint.coordinates.lng;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Drag and zoom the map to reposition the pin.",
            style: TextStyle(fontSize: 16),
          ),
        ),
        SizedBox(
          height: mapHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              MapWidget(
                cameraOptions: CameraOptions(
                  center: _initialPoint,
                  zoom: 16.0,
                ),
                onMapCreated: (mapboxMap) async {
                  _mapboxMap = mapboxMap;
                  _mapboxMap.compass
                      .updateSettings(CompassSettings(enabled: false));
                  _mapboxMap.scaleBar
                      .updateSettings(ScaleBarSettings(enabled: false));
                  _mapboxMap.gestures.updateSettings(GesturesSettings(
                      rotateEnabled: false, pitchEnabled: false));
                },
                onCameraChangeListener: (CameraChangedEventData _) async {
                  final cameraState = await _mapboxMap.getCameraState();
                  setState(() {
                    _currentCenter = cameraState.center;
                  });
                },
              ),
              Positioned(
                bottom: mapHeight / 2,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/misc.png',
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
                      if (_hasChanged())
          Positioned(
              top: 8,
              left: 8,
              child: TextButton.icon(
                style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
                icon: const Icon(Icons.refresh),
                label: const Text("Reset Pin"),
                onPressed: _resetMapCamera,
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text("Cancel"),
              onPressed: widget.onCancel,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Confirm Pin Placement"),
              onPressed: () {
                if (_currentCenter != null) {
                  widget.onLocationChanged(_currentCenter!);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
