import 'dart:async';
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
  final List<PublicSpaceFeature> features;

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
      this.favorites = const [],
      this.features = const []});

  @override
  _MapHandlerState createState() => _MapHandlerState();
}

class _MapHandlerState extends State<MapHandler> {
  late MapboxMap mapboxMap;
  PointAnnotationManager? markerPointAnnotationManager;
  PointAnnotationManager? heartAnnotationManager;
  PointAnnotationManager? heartSelectedAnnotationManager;

  Uint8List? _iconBytes;
  Uint8List? _heartBadgeBytes;

  double _heartOpacity = 0.0; // hidden until zoom >= 13
  Timer? _zoomDebounceTimer;
  bool _sourceAdded = false;

  @override
  void initState() {
    super.initState();
    _loadFontAwesomeIcon();
    _loadHeartBadge();
  }

  @override
  void dispose() {
    _zoomDebounceTimer?.cancel();
    super.dispose();
  }

  void _handleCameraChange(CameraChangedEventData event) {
    widget.onCameraChangeListener?.call(event);

    _zoomDebounceTimer?.cancel();
    _zoomDebounceTimer = Timer(const Duration(milliseconds: 50), () async {
      if (!mounted) return;
      final state = await mapboxMap.getCameraState();
      if (!mounted) return;
      final zoom = state.zoom;
      final newOpacity = zoom < 13.1
          ? 0.0
          : zoom > 13.2
              ? 1.0
              : (zoom - 13.0) / 0.1;
      if ((newOpacity - _heartOpacity).abs() > 0.02) {
        _heartOpacity = newOpacity;
        await _updateHeartAnnotations();
        await _updateSelectedHeartAnnotation();
      }
    });
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
        iconOpacity: _heartOpacity,
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
      iconOffset: [9.0, -24.0],
      iconOpacity: 1.0,
    ));
  }

  // Detect changes in selectedFeature and update the map accordingly
  @override
  void didUpdateWidget(MapHandler oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedFeature != oldWidget.selectedFeature) {
      _updateSelectedLayer(widget.selectedFeature?.properties.firestoreId);
      _updateHeartAnnotations();
      _updateSelectedHeartAnnotation();
    }

    final oldFeatureCount = oldWidget.features.length;
    final newFeatureCount = widget.features.length;
    if (oldFeatureCount != newFeatureCount && widget.features.isNotEmpty) {
      if (!_sourceAdded) {
        _addSpaceSourceAndLayers(widget.features);
      } else {
        _updateSpaceSourceData(widget.features);
      }
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

  void _updateSelectedLayer(String? firestoreId) {
    if (!_sourceAdded) return;
    final filter = firestoreId != null
        ? ['==', ['get', 'firestoreId'], firestoreId]
        : ['==', ['get', 'firestoreId'], ''];
    mapboxMap.style.setStyleLayerProperty(
      'spaces-selected',
      'filter',
      jsonEncode(filter),
    );
  }

  Future<void> _addStyleImages() async {
    final images = {
      'park':  widget.parkImage,
      'wpaa':  widget.wpaaImage,
      'pops':  widget.popsImage,
      'plaza': widget.plazaImage,
      'stp':   widget.stpImage,
      'misc':  widget.miscImage,
    };

    for (final entry in images.entries) {
      try {
        final codec = await ui.instantiateImageCodec(entry.value);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData == null) {
          print('addStyleImage: null byteData for ${entry.key}');
          continue;
        }
        print('addStyleImage ${entry.key}: ${image.width}x${image.height}, ${byteData.lengthInBytes} bytes');
        await mapboxMap.style.addStyleImage(
          entry.key,
          1.0,
          MbxImage(
            width: image.width,
            height: image.height,
            data: byteData.buffer.asUint8List(),
          ),
          false, [], [], null,
        );
      } catch (e) {
        print('addStyleImage error for ${entry.key}: $e');
      }
    }
  }

  Map<String, dynamic> _buildFeatureCollection(List<PublicSpaceFeature> features) {
    return {
      'type': 'FeatureCollection',
      'features': features.map((f) {
        final json = f.toJson();
        json['id'] = f.properties.firestoreId; // required for feature state
        return json;
      }).toList(),
    };
  }

  Future<void> _addSpaceSourceAndLayers(List<PublicSpaceFeature> features) async {
    await _addStyleImages();

    await mapboxMap.style.addSource(GeoJsonSource(
      id: 'public-spaces',
      data: jsonEncode(_buildFeatureCollection(features)),
    ));

    const iconImageExpr = [
      'match', ['get', 'type'],
      'park', 'park', 'wpaa', 'wpaa', 'pops', 'pops',
      'plaza', 'plaza', 'stp', 'stp', 'misc',
    ];

    await mapboxMap.style.addStyleLayer(jsonEncode({
      'id': 'spaces-layer',
      'type': 'circle',
      'source': 'public-spaces',
      'paint': {
        'circle-emissive-strength': 1,
        'circle-color': ['match', ['get', 'type'],
          'park',  '#77bb3f',
          'wpaa',  '#0ad6f5',
          'pops',  '#6b82d6',
          'plaza', '#ffbf47',
          'stp',   '#F55353',
          '#CCCCCC',
        ],
        'circle-radius': ['interpolate', ['linear'], ['zoom'], 12, 3, 14, 8],
        'circle-stroke-width': ['interpolate', ['linear'], ['zoom'], 10, 1, 13, 2],
        'circle-stroke-color': '#ffffff',
        'circle-opacity': ['interpolate', ['linear'], ['zoom'], 13, 1, 13.1, 0],
        'circle-stroke-opacity': ['interpolate', ['linear'], ['zoom'], 13, 1, 13.1, 0],
      },
    }), null);

    await mapboxMap.style.addStyleLayer(jsonEncode({
      'id': 'spaces-marker',
      'type': 'symbol',
      'source': 'public-spaces',
      'layout': {
        'icon-image': iconImageExpr,
        'icon-size': 0.3,
        'icon-anchor': 'bottom',
        'icon-allow-overlap': true,
        'text-allow-overlap': true,
        'text-size': 12,
        'text-offset': [0, -3],
        'text-anchor': 'bottom',
        'text-letter-spacing': 0.2,
      },
      'paint': {
        'icon-opacity': ['interpolate', ['linear'], ['zoom'], 13, 0, 13.1, 1],
        'text-halo-color': '#ffffff',
        'text-halo-width': 1.4,
        'text-opacity': ['interpolate', ['linear'], ['zoom'], 15, 0, 15.1, 1],
        'text-color': '#2b2b2b',
      },
    }), null);

    await mapboxMap.style.addStyleLayer(jsonEncode({
      'id': 'spaces-label',
      'type': 'symbol',
      'source': 'public-spaces',
      'layout': {
        'icon-image': iconImageExpr,
        'icon-size': 0.3,
        'icon-anchor': 'bottom',
        'icon-allow-overlap': true,
        'text-field': ['to-string', ['get', 'name']],
        'text-font': ['Poppins Regular', 'Arial Unicode MS Regular'],
        'text-size': 12,
        'text-offset': [0, -3],
        'text-anchor': 'bottom',
        'text-letter-spacing': 0.2,
      },
      'paint': {
        'icon-opacity': ['interpolate', ['linear'], ['zoom'], 14, 0, 14.1, 1],
        'text-halo-color': '#ffffff',
        'text-halo-width': 1.4,
        'text-opacity': ['interpolate', ['linear'], ['zoom'], 15, 0, 15.1, 1],
        'text-color': '#2b2b2b',
      },
    }), null);

    // Selected feature layer — filter updated dynamically on tap
    await mapboxMap.style.addStyleLayer(jsonEncode({
      'id': 'spaces-selected',
      'type': 'symbol',
      'source': 'public-spaces',
      'filter': ['==', ['get', 'firestoreId'], ''],
      'layout': {
        'icon-image': iconImageExpr,
        'icon-size': 0.45,
        'icon-anchor': 'bottom',
        'icon-allow-overlap': true,
      },
      'paint': {
        'icon-opacity': 1.0,
      },
    }), null);

    // Annotation managers created last so they render above all style layers
    markerPointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    heartAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    heartSelectedAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    _updateHeartAnnotations();
    _updateSelectedHeartAnnotation();

    _sourceAdded = true;
  }

  Future<void> _updateSpaceSourceData(List<PublicSpaceFeature> features) async {
    await mapboxMap.style.setStyleSourceProperty(
      'public-spaces',
      'data',
      jsonEncode(_buildFeatureCollection(features)),
    );
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

    if (widget.features.isNotEmpty) {
      await _addSpaceSourceAndLayers(widget.features);
    }
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
            RenderedQueryOptions(
                layerIds: ['spaces-layer', 'spaces-marker', 'spaces-label'],
                filter: null))
        .then((features) async {
      if (features.isNotEmpty) {
        // Parse the feature and call the parent callback

        var geojsonFeatureString =
            jsonEncode(features[0]!.queriedFeature.feature);

        PublicSpaceFeature geojsonFeature =
            PublicSpaceFeature.fromJson(jsonDecode(geojsonFeatureString));

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
      styleUri: 'mapbox://styles/chriswhongmapbox/cmpq8s9qs007401s76cfp5xmv',
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(-74.00299, 40.70966)),
        zoom: 12,
      ),
      onMapCreated: _onMapCreated,
      onCameraChangeListener: _handleCameraChange,
      onTapListener: (MapContentGestureContext gestureContext) =>
          _onMapTapListener(context, gestureContext), // Pass context here,
    );
  }
}
