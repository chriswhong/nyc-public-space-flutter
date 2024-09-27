import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class MapHandler {
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PanelController? _pc;
  final Function onMapCreated;

  MapHandler( this.onMapCreated);

  Function(String)? updatePanelContent;

  void init(PanelController pc, Function(String) updateContent) {
    _pc = pc;
    updatePanelContent = updateContent;
  }

  // Function calling _getFeatures with context
  _onMapLoaded(MapLoadedEventData) async {
    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    // limit bounds
    mapboxMap.setBounds(CameraBoundsOptions(minZoom: 10));

    // disable compass, scalebar, and rotation
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.gestures.updateSettings(GesturesSettings(rotateEnabled: false));

    var status = await Permission.locationWhenInUse.request();
    print("Location granted : $status");

    mapboxMap.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true));

    this.onMapCreated(mapboxMap);
  }

  _onMapTapListener(MapContentGestureContext context) async {
    pointAnnotationManager?.deleteAll();

    mapboxMap
        .queryRenderedFeatures(
            RenderedQueryGeometry(
                value: json.encode(ScreenCoordinate(
                        x: context.touchPosition.x, y: context.touchPosition.y)
                    .encode()),
                type: Type.SCREEN_COORDINATE),
            RenderedQueryOptions(layerIds: [
              'park-centroids',
              'wpaa-centroids',
              'pops-centroids',
              'plaza-centroids'
            ], filter: null))
        .then((features) async {
      if (features.isNotEmpty) {
        var geojsonFeatureString =
            jsonEncode(features[0]!.queriedFeature.feature);

        Feature geojsonFeature =
            Feature.fromJson(jsonDecode(geojsonFeatureString));

        Point point =
            Point.fromJson(jsonDecode(jsonEncode(geojsonFeature.geometry)));

        // flyTo the clicked feature

        // mapboxMap.flyTo(
        //     CameraOptions(
        //       center: point,
        //     ),
        //     null);

        // add a marker

        // Load the marker image as Uint8List
        Uint8List imageData = await rootBundle
            .load('assets/map-marker.png')
            .then((byteData) => byteData.buffer.asUint8List());

        // Create PointAnnotationOptions with the extracted coordinates
        PointAnnotationOptions annotationOptions = PointAnnotationOptions(
          geometry: point, // Use the geometry directly
          iconSize: 0.4, // Optional: Adjust size
          image: imageData, // Optional: Provide your icon image name,
          iconAnchor: IconAnchor.BOTTOM,
        );

        // // Add the point annotation to the map
        pointAnnotationManager?.create(annotationOptions);
        var properties = features[0]!.queriedFeature.feature['properties'];
        if (properties != null && properties is Map<Object?, Object?>) {
          var signname = (properties['name'] as String?) ?? 'Unnamed Space';
          updatePanelContent!(signname);
        }
        _pc!.open();
      }
    });
  }

  _onMapScrollListener(MapContentGestureContext context) {
    // when the user moves the map, close the panel
    if (_pc != null && _pc!.isPanelOpen) {
      _pc!.close();
    }
    // pointAnnotationManager?.deleteAll;
  }

  Widget buildMap() {
    return MapWidget(
      styleUri: 'mapbox://styles/chriswhongmapbox/clzu4xoh900oz01qsgnxq8sf1',
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(-73.96, 40.75183)),
        zoom: 13,
      ),
      onMapCreated: _onMapCreated,
      onTapListener: _onMapTapListener,
      onScrollListener: _onMapScrollListener,
      onMapLoadedListener: _onMapLoaded,
    );
  }
}
