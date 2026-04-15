import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'favorites_provider.dart';

Future<Uint8List> getFontAwesomeIconAsBytes({
  FaIconData icon = FontAwesomeIcons.mapMarkerAlt,
  double size = 64,
  Color color = Colors.red,
}) async {
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);

  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  textPainter.text = TextSpan(
    text: String.fromCharCode(icon.codePoint),
    style: TextStyle(
      fontSize: size,
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      color: color,
    ),
  );

  textPainter.layout();
  textPainter.paint(canvas, Offset.zero);

  final picture = pictureRecorder.endRecording();
  final image = await picture.toImage(
    textPainter.width.toInt(),
    textPainter.height.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  return bytes!.buffer.asUint8List();
}

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
  final Feature? markerFeature;
  final void Function(CameraChangedEventData)? onCameraChangeListener;
  final List<FavoriteItem> favorites;

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
      required this.miscImage,
      required this.markerFeature,
      this.onCameraChangeListener,
      this.favorites = const []});

  @override
  _MapHandlerState createState() => _MapHandlerState();
}

class _MapHandlerState extends State<MapHandler> {
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PointAnnotationManager? markerPointAnnotationManager;
  PointAnnotationManager? heartAnnotationManager;
  PointAnnotationManager? heartSelectedAnnotationManager;

  Uint8List? _iconBytes;
  Uint8List? _heartBadgeBytes;

  @override
  void initState() {
    super.initState();
    _loadFontAwesomeIcon();
    _loadHeartBadge();
  }

  Future<void> _loadFontAwesomeIcon() async {
    final bytes = await getFontAwesomeIconAsBytes(
      icon: FontAwesomeIcons.mapMarkerAlt,
      size: 64,
      color: Colors.red,
    );
    setState(() {
      _iconBytes = bytes;
    });
  }

  Future<void> _loadHeartBadge() async {
    const double size = 48;
    const double iconSize = 26;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Filled circle background
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = const Color(0xFFE53935),
    );
    // White border for contrast
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 1.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // White heart icon centered in the circle
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(FontAwesomeIcons.solidHeart.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: FontAwesomeIcons.solidHeart.fontFamily,
        package: FontAwesomeIcons.solidHeart.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    _heartBadgeBytes = bytes!.buffer.asUint8List();
    // Re-draw badges now that the image is ready (favorites may already be set)
    _updateHeartAnnotations();
  }

  // Normal-size heart badges for all favorited features except the selected one.
  Future<void> _updateHeartAnnotations() async {
    if (heartAnnotationManager == null || _heartBadgeBytes == null) return;
    await heartAnnotationManager!.deleteAll();

    final selectedId = widget.selectedFeature?.properties.firestoreId;
    for (final item in widget.favorites) {
      if (item.firestoreId == selectedId) continue; // handled by selected manager
      await heartAnnotationManager!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(item.lng, item.lat)),
        image: _heartBadgeBytes,
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
        iconOffset: [10.0, -23.0],
      ));
    }
  }

  // Scaled heart badge for the selected feature (matches 1.5× enlarged marker).
  Future<void> _updateSelectedHeartAnnotation() async {
    if (heartSelectedAnnotationManager == null || _heartBadgeBytes == null) return;
    await heartSelectedAnnotationManager!.deleteAll();

    final selected = widget.selectedFeature;
    if (selected == null) return;
    final isFav = widget.favorites.any((f) => f.firestoreId == selected.properties.firestoreId);
    if (!isFav) return;

    await heartSelectedAnnotationManager!.create(PointAnnotationOptions(
      geometry: selected.geometry,
      image: _heartBadgeBytes,
      iconSize: 1.5,
      iconAnchor: IconAnchor.BOTTOM,
      iconOffset: [15.0, -35.0],
    ));
  }

  // Detect changes in selectedFeature and update the map accordingly
  @override
  void didUpdateWidget(MapHandler oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedFeature != oldWidget.selectedFeature) {
      _updateAnnotations(widget.selectedFeature);
      _updateHeartAnnotations();       // re-exclude/include the newly selected id
      _updateSelectedHeartAnnotation(); // show/hide scaled badge on selected marker
    }

    final oldIds = oldWidget.favorites.map((f) => f.firestoreId).toSet();
    final newIds = widget.favorites.map((f) => f.firestoreId).toSet();
    if (!oldIds.containsAll(newIds) || !newIds.containsAll(oldIds)) {
      _updateHeartAnnotations();
      _updateSelectedHeartAnnotation();
    }

    if (jsonEncode(widget.markerFeature?.toJson()) !=
        jsonEncode(oldWidget.markerFeature?.toJson())) {
      final geometry = widget.markerFeature?.geometry;

      if (geometry != null) {

        mapboxMap.flyTo(
            CameraOptions(center: Point.fromJson(geometry.toJson()), zoom: 15),
            MapAnimationOptions(duration: 2000));

        markerPointAnnotationManager?.deleteAll();

        // Create annotation options
        final namePreferred = widget.markerFeature?.properties?['name_preferred'];
        final name = widget.markerFeature?.properties?['name'];
        final textField = (namePreferred != null && namePreferred.isNotEmpty) ? namePreferred : name;
        
        PointAnnotationOptions annotationOptions = PointAnnotationOptions(
          geometry: Point.fromJson(geometry.toJson()),
          iconSize: 1.5,
          image: _iconBytes,
          textField: textField,
          textAnchor: TextAnchor.LEFT,
          textOffset: [1.5, -1.3],
          textColor: Colors.black.value, 
          textHaloColor: Colors.white.value,
          textHaloWidth: 1.5,
          iconAnchor: IconAnchor.BOTTOM,
        );

        // Add annotation to the map
        markerPointAnnotationManager?.create(annotationOptions);
      } else {
        markerPointAnnotationManager?.deleteAll();
      }
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

    // position logo and attribution above the bottom info panel
    mapboxMap.logo
        .updateSettings(LogoSettings(marginBottom: 90, marginLeft: 15));
    mapboxMap.attribution.updateSettings(AttributionSettings(
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginBottom: 90,
        marginRight: 10));

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

    // Initialize PointAnnotationManagers (order matters for z-layering)
    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    markerPointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    // Normal heart badges (non-selected favorites)
    heartAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    // Scaled heart badge for the selected feature — created last so it's on top
    heartSelectedAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    _updateHeartAnnotations();
    _updateSelectedHeartAnnotation();
  }

  _onMapTapListener(
      BuildContext buildContext, MapContentGestureContext context) async {
    // Capture MediaQuery values before the async gap
    final mq = MediaQuery.of(buildContext);
    final double topInset = mq.viewPadding.top + 64;
    final double bottomInset = mq.size.height * 0.40;

    mapboxMap
        .queryRenderedFeatures(
            RenderedQueryGeometry.fromScreenCoordinate(ScreenCoordinate(
                x: context.touchPosition.x, y: context.touchPosition.y)),
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


        // Call parent callback to update the selectedFeature in parent state
        widget.onFeatureSelected(geojsonFeature);

        // Center the point in the visible area between the search bar and
        // the panel at its default 40% open height.
        mapboxMap.flyTo(
          CameraOptions(
            center: geojsonFeature.geometry,
            padding: MbxEdgeInsets(
              top: topInset,
              right: 0,
              bottom: bottomInset,
              left: 0,
            ),
          ),
          MapAnimationOptions(),
        );
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
      onCameraChangeListener: widget.onCameraChangeListener,
      onTapListener: (MapContentGestureContext gestureContext) =>
          _onMapTapListener(context, gestureContext), // Pass context here,
    );
  }
}
