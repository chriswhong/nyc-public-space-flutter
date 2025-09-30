import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import './draggable_mapbox_marker.dart';
import './positioned_map_marker.dart';

final GlobalKey _mapContainerKey = GlobalKey();
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

  final String mapboxAccessToken = const String.fromEnvironment("ACCESS_TOKEN");

  @override
  void initState() {
    super.initState();
    _currentPoint = widget.initialPoint;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStaticImage(); // once layout is complete
    });
  }

  Future<void> _fetchStaticImage() async {
    final context = _mapContainerKey.currentContext;
    if (context == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final width =
        (size.width * MediaQuery.of(context).devicePixelRatio).round();
    final height =
        (size.height * MediaQuery.of(context).devicePixelRatio).round();

    final imageWidth = (width / 4).round();
    final imageHeight = (height / 4).round();
    final lon = _currentPoint.coordinates.lng;
    final lat = _currentPoint.coordinates.lat;

    final url =
        'https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/$lon,$lat,16/${imageWidth}x$imageHeight@2x?access_token=$mapboxAccessToken';

    print(url);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() {
        _staticImage = response.bodyBytes;
      });
    } else {
      print('Failed to load static map image');
    }
  }

  Future<void> _editLocation(BuildContext context) async {
    final newPoint = await Navigator.of(context).push<Point>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text("Set Pin Location"),
              automaticallyImplyLeading: false, // 👈 hides the default chevron
            ),
            body: DraggableMapboxMarker(
              initialPoint: _currentPoint,
              type: widget.type,
              onCancel: () =>
                  Navigator.of(context).pop(), // your custom handler
              onLocationChanged: (point) {
                Navigator.of(context).pop(point);
              },
            )),
      ),
    );

    if (newPoint != null) {
      setState(() {
        _currentPoint = newPoint;
      });
      widget.onLocationChanged(newPoint);
      _fetchStaticImage(); // reload with new coordinates
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Rounded border container for the map image
        Container(
          key: _mapContainerKey,
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

        // Positioned "Edit Pin" button
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
