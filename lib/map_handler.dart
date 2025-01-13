import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:geolocator/geolocator.dart' as geo;

class MapHandler extends StatefulWidget {
  final PublicSpaceFeature? selectedFeature; // Pass selectedFeature from parent
  final Function(PublicSpaceFeature)
      onFeatureSelected; // Callback to select feature
  final Function(MapboxMap) onMapCreated;
  final Uint8List parkImage;
  final Uint8List wpaaImage;
  final Uint8List popsImage;
  final Uint8List plazaImage;
  final Uint8List stpImage;
  final Uint8List miscImage;

  const MapHandler(
      {super.key,
      required this.selectedFeature,
      required this.onMapCreated,
      required this.onFeatureSelected,
      required this.parkImage,
      required this.wpaaImage,
      required this.popsImage,
      required this.plazaImage,
      required this.stpImage,
      required this.miscImage});

  @override
  _MapHandlerState createState() => _MapHandlerState();
}

class _MapHandlerState extends State<MapHandler> {
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  @override
  void initState() {
    super.initState();
  }

  // Detect changes in selectedFeature and update the map accordingly
  @override
  void didUpdateWidget(MapHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFeature != oldWidget.selectedFeature) {
      _updateAnnotations(widget.selectedFeature);
    }
  }

  // Method to add annotation for the active feature
  void _updateAnnotations(PublicSpaceFeature? feature) async {
    // Clear any existing annotations
    pointAnnotationManager?.deleteAll();
    if (feature == null) {
      return; // Exit early if feature is null
    }

    // Ensure pointAnnotationManager is ready
    if (pointAnnotationManager != null) {
      // Select image based on the feature type
      Uint8List selectedImage;
      if (feature.properties.type == 'park') {
        selectedImage = widget.parkImage;
      } else if (feature.properties.type == 'wpaa') {
        selectedImage = widget.wpaaImage;
      } else if (feature.properties.type == 'pops') {
        selectedImage = widget.popsImage;
      } else if (feature.properties.type == 'plaza') {
        selectedImage = widget.plazaImage;
      } else if (feature.properties.type == 'stp') {
        selectedImage = widget.stpImage;
      } else {
        selectedImage = widget.miscImage; // Fallback to an empty image
      }

      // Create annotation options
      PointAnnotationOptions annotationOptions = PointAnnotationOptions(
        geometry: feature
            .geometry, // Assuming the feature has a geometry of type Point
        iconSize: 1.5,
        image: selectedImage,
        iconAnchor: IconAnchor.BOTTOM,
      );

      // Add annotation to the map
      pointAnnotationManager?.create(annotationOptions);
    }
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    // set the map instance for use later
    this.mapboxMap = mapboxMap;
    // set minimum zoom
    mapboxMap.setBounds(CameraBoundsOptions(
        minZoom: 10,
        bounds: CoordinateBounds(
            southwest: Point(coordinates: Position(-74.68918, 40.36277)),
            northeast: Point(coordinates: Position(-73.31198, 41.16886)),
            infiniteBounds: false)));

    // disable compass, scalebar, and rotation
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.gestures.updateSettings(GesturesSettings(rotateEnabled: false));

    // position logo and attribution
    mapboxMap.logo
        .updateSettings(LogoSettings(marginBottom: 90, marginLeft: 15));
    mapboxMap.attribution.updateSettings((AttributionSettings(
        position: OrnamentPosition.BOTTOM_LEFT,
        marginBottom: 90,
        marginLeft: 110)));

    // get location permission from the device
    var status = await Permission.locationWhenInUse.request();
    print("Location granted : $status");

    mapboxMap.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true));

    // fly map to user location
    var position = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );

    mapboxMap.flyTo(
        CameraOptions(
            zoom: 15,
            center: Point(
                coordinates: Position(position.longitude, position.latitude))),
        null);

    // call onMapCreated callback to pass the map instance upward
    widget.onMapCreated(mapboxMap);

    // Initialize PointAnnotationManager
    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
  }

  _onMapTapListener(
      BuildContext buildContext, MapContentGestureContext context) async {
    mapboxMap
        .queryRenderedFeatures(
            RenderedQueryGeometry(
                value: json.encode(ScreenCoordinate(
                        x: context.touchPosition.x, y: context.touchPosition.y)
                    .encode()),
                type: Type.SCREEN_COORDINATE),
            RenderedQueryOptions(layerIds: [
              'park-centroids',
              'park-marker',
              'wpaa-centroids',
              'wpaa-marker',
              'pops-centroids',
              'pops-marker',
              'plaza-centroids',
              'plaza-marker',
              'stp-centroids',
              'stp-marker',
              'misc-centroids',
              'misc-marker'
            ], filter: null))
        .then((features) async {
      if (features.isNotEmpty) {
        // Parse the feature and call the parent callback

        var geojsonFeatureString =
            jsonEncode(features[0]!.queriedFeature.feature);

        PublicSpaceFeature geojsonFeature =
            PublicSpaceFeature.fromJson(jsonDecode(geojsonFeatureString));

        String firestoreId = geojsonFeature.properties.firestoreId;

        print('Clicked feature: $firestoreId');

        // Call parent callback to update the selectedFeature in parent state
        widget.onFeatureSelected(geojsonFeature);

        // animate map if screen coordinate was in bottom 20% of screen
        double screenHeight = MediaQuery.of(buildContext).size.height;
        double yPercent = context.touchPosition.y / screenHeight;

        if (yPercent > .50) {
          mapboxMap.flyTo(CameraOptions(center: geojsonFeature.geometry),
              MapAnimationOptions());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      styleUri: 'mapbox://styles/chriswhongmapbox/clzu4xoh900oz01qsgnxq8sf1',
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(-74.00299, 40.70966)),
        zoom: 12,
      ),
      onMapCreated: _onMapCreated,
      onTapListener: (MapContentGestureContext gestureContext) =>
          _onMapTapListener(context, gestureContext), // Pass context here,
    );
  }
}
