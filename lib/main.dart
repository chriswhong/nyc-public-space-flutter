import 'dart:convert';

import 'package:flutter/services.dart'; // For rootBundle
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  final PanelController _pc = PanelController();

  String _panelContent = '';
  double _fabHeight = 0;

  final double _closedFabPosition =
      120.0; // Distance from the bottom when the panel is collapsed
  final double _openFabPosition =
      300.0; // Distance from the bottom when the panel is fully opened

  // update the panel content
  void updatePanelContent(String newContent) {
    setState(() {
      _panelContent = newContent;
    });
  }

  _onMapTapListener(MapContentGestureContext context) async {
    var renderedQueryGeometry = RenderedQueryGeometry(
        value: json.encode(ScreenCoordinate(
                x: context.touchPosition.x, y: context.touchPosition.y)
            .encode()),
        type: Type.SCREEN_COORDINATE);

    mapboxMap
        .queryRenderedFeatures(
            renderedQueryGeometry,
            RenderedQueryOptions(layerIds: [
              'parks-properties-centroids',
              'waterfront-public-access-areas',
              'pops',
              'pedestrian-plazas-centroids'
            ], filter: null))
        .then((features) {
      if (features.isNotEmpty) {
        var layer = features[0]!.layers[0];
        var properties = features[0]!.queriedFeature.feature['properties'];
        if (layer == 'parks-properties-centroids') {
          if (properties != null && properties is Map<Object?, Object?>) {
            var signname = properties['signname'] as String;
            updatePanelContent(signname);
          }
        }

        _pc.open();
      }
    });
  }

  _onMapScrollListener(MapContentGestureContext context) {
    if (_pc.isPanelOpen) {
      _pc.close();
    }
  }

  _getFeatures() async {
    // Get the map size (viewport dimensions)

    var screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;

    print(screenWidth);
    print(screenHeight);

    // Create the screen box (viewport) using the corner coordinates
    var screenBox = ScreenBox(
        min: ScreenCoordinate(x: 0, y: 0),
        max: ScreenCoordinate(x: screenWidth, y: screenHeight));

    // Query rendered features for a specific layer within the current viewport
    var features = await mapboxMap.queryRenderedFeatures(
      RenderedQueryGeometry(
          value: json.encode(screenBox.encode()), type: Type.SCREEN_BOX),
      RenderedQueryOptions(
        layerIds: ['parks-properties-centroids'],
      ),
    );

    final pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    // Load the image as Uint8List
    Uint8List imageData = await rootBundle
        .load('assets/map-marker.png')
        .then((byteData) => byteData.buffer.asUint8List());

    for (var feature in features) {
      // Extract the geometry point from the feature
      var geojsonGeometry =
          jsonEncode(feature?.queriedFeature.feature['geometry']);

      Point point = Point.fromJson(jsonDecode(geojsonGeometry));

      // Create PointAnnotationOptions with the extracted coordinates
      PointAnnotationOptions annotationOptions = PointAnnotationOptions(
        geometry: point, // Use the geometry directly
        iconSize: 0.4, // Optional: Adjust size
        image: imageData, // Optional: Provide your icon image name
      );

      // // Add the point annotation to the map
      pointAnnotationManager.create(annotationOptions);
    }
  }

  _onMapLoaded(MapLoadedEventData) async {
    _getFeatures();
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    //  Size mapSize = await mapboxMap.getSize();

    print(mapboxMap);

    // limit bounds
    mapboxMap.setBounds(CameraBoundsOptions(minZoom: 10));

    // map settings
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.gestures.updateSettings(GesturesSettings(rotateEnabled: false));

    var status = await Permission.locationWhenInUse.request();
    print("Location granted : $status");

    mapboxMap.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true));

    print(mapboxMap.location.getSettings().then((value) {
      print(value);
      print('location shown');
    }));

    
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();

    // Pass your access token to MapboxOptions so you can load a map
    String accessToken = const String.fromEnvironment("ACCESS_TOKEN");

    MapboxOptions.setAccessToken(accessToken);

    // Define options for your camera
    CameraOptions camera = CameraOptions(
      center: Point(coordinates: Position(-73.96, 40.75183)),
      zoom: 13,
    );

    return MaterialApp(
        title: 'Flutter Demo',
        home: Scaffold(
          body: Stack(children: <Widget>[
            SlidingUpPanel(
              controller: _pc,
              panel: Center(
                child: Text(
                  _panelContent,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              onPanelSlide: (position) {
                setState(() {
                  // Dynamically change the FAB position based on the panel's position (between 0.0 and 1.0)
                  _fabHeight = _closedFabPosition +
                      (_openFabPosition - _closedFabPosition) * position;
                });
              },
              body: MapWidget(
                styleUri:
                    'mapbox://styles/chriswhongmapbox/clzu4xoh900oz01qsgnxq8sf1',
                cameraOptions: camera,
                onMapCreated: _onMapCreated,
                onTapListener: _onMapTapListener,
                onScrollListener: _onMapScrollListener,
                onMapLoadedListener: _onMapLoaded,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18.0)),
              minHeight: 100, // The height of the collapsed panel
              maxHeight: 300, // The height of the expanded panel
            ),
            Positioned(
              right: 20.0,
              bottom:
                  _fabHeight, // Adjust this value to position the button above the sliding panel
              child: FloatingActionButton(
                onPressed: () {
                  // You can also control the panel from here if needed
                },
                backgroundColor: Colors.white,
                child: const FaIcon(
                  FontAwesomeIcons.locationArrow,
                  color: Colors.blue,
                ),
              ),
            ),
          ]),
          // body:
        ));
  }
}
