import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'main.dart' show mapboxAccessToken;

import './draggable_mapbox_marker.dart';
import './positioned_map_marker.dart';

const double mapHeight = 230;

class StaticMapWithEdit extends StatefulWidget {
  final Point initialPoint;
  final String type;
  final void Function(Point) onLocationChanged;

  const StaticMapWithEdit({
    super.key,
    required this.initialPoint,
    required this.type,
    required this.onLocationChanged,
  });

  @override
  State<StaticMapWithEdit> createState() => _StaticMapWithEditState();
}

class _StaticMapWithEditState extends State<StaticMapWithEdit> {
  late Point _currentPoint;
  Uint8List? _staticImage;

  @override
  void initState() {
    super.initState();
    _currentPoint = widget.initialPoint;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchStaticImage());
  }

  Future<void> _fetchStaticImage() async {
    if (!mounted) return;
    final token = mapboxAccessToken;
    if (!mounted) return;

    final mq = MediaQuery.of(context);
    final imageWidth = ((mq.size.width - 32).clamp(0, 1280)).round();
    final imageHeight = mapHeight.round();
    final lon = _currentPoint.coordinates.lng;
    final lat = _currentPoint.coordinates.lat;

    final url =
        'https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/$lon,$lat,16/${imageWidth}x${imageHeight}@2x?access_token=$token';

    debugPrint('Static map URL: $url');
    final response = await http.get(Uri.parse(url));
    if (mounted && response.statusCode == 200) {
      setState(() => _staticImage = response.bodyBytes);
    }
  }

  Future<void> _editLocation(BuildContext context) async {
    final newPoint = await Navigator.of(context).push<Point>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text("Set Pin Location"),
            automaticallyImplyLeading: false,
          ),
          body: DraggableMapboxMarker(
            initialPoint: _currentPoint,
            type: widget.type,
            onCancel: () => Navigator.of(context).pop(),
            onLocationChanged: (point) => Navigator.of(context).pop(point),
          ),
        ),
      ),
    );

    if (newPoint != null) {
      setState(() {
        _currentPoint = newPoint;
        _staticImage = null;
      });
      widget.onLocationChanged(newPoint);
      _fetchStaticImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: mapHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          clipBehavior: Clip.hardEdge,
          child: _staticImage != null
              ? Image.memory(
                  _staticImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => _editLocation(context),
            child: const Text("Edit Pin"),
          ),
        ),
        PositionedMapMarker(type: widget.type, mapHeight: mapHeight),
      ],
    );
  }
}
