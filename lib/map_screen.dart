import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nyc_public_space_map/colors.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'package:nyc_public_space_map/map_handler.dart';
import 'package:nyc_public_space_map/panel/panel_handler.dart';
// import 'package:nyc_public_space_map/search_handler.dart';
import 'search_widget.dart';
import 'package:nyc_public_space_map/image_loader.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/map_controls.dart';

class MapScreen extends StatefulWidget {
  final Function(PublicSpaceFeature?) onReportAnIssue;

  const MapScreen({super.key, required this.onReportAnIssue});

  @override
  State createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final PanelController _pc = PanelController();

  MapboxMap? mapboxMap;
  PublicSpaceFeature? selectedFeature;

  User? currentUser; // Firebase User instance

  Feature? markerFeature;

  // Panel state
  bool _panelVisible = false;  // controls whether SlidingUpPanel is in the tree
  bool _panelExpanded = false; // true when panel is near max (for scrim)
  double _maxPanelHeight = 600.0; // cached from LayoutBuilder, updated each build

  // Map controls state
  bool _tracking = false;
  bool _pitchButtonActive = false;
  DateTime _pitchSettleUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isAnimating = false;
  StreamSubscription<geo.Position>? _locationSubscription;

  void _setMarkerFeature(Feature? newMarkerFeature) {
    setState(() {
      markerFeature = newMarkerFeature;
    });
  }

  void _onLocalResultSelected(PublicSpaceFeature? geojsonFeature) {
    if (geojsonFeature != null) {
      // fly map to the selected feature, centered in the visible area between
      // the search bar and the panel at its default 40% open height.
      final geometry = geojsonFeature.geometry;
      if (geometry != null) {
        final mq = MediaQuery.of(context);
        final double topInset = mq.viewPadding.top + 64; // safe area + search bar
        final double bottomInset = mq.size.height * 0.40; // panel at 40%

        mapboxMap?.flyTo(
          CameraOptions(
            zoom: 15,
            center: Point.fromJson(geometry.toJson()),
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

      _onFeatureSelected(geojsonFeature);
    }
  }

  @override
  void initState() {
    super.initState();
    ImageLoader.instance.loadImages();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkCurrentUser() async {
    setState(() {
      currentUser = FirebaseAuth.instance.currentUser; // Get the current user
    });
  }

  void _onMapCreated(MapboxMap mapInstance) {
    setState(() {
      mapboxMap = mapInstance;
    });
    mapInstance.setOnMapMoveListener((_) {
      if (_tracking && !_isAnimating && mounted) {
        setState(() => _tracking = false);
        _locationSubscription?.cancel();
        _locationSubscription = null;
      }
      // Shrink panel to peek on any map gesture
      if (!_isAnimating && mounted && _panelVisible) {
        try {
          _pc.close(); // animates to minHeight (peek = 106px)
        } catch (_) {}
      }
    });
  }

  void _toggleTracking() async {
    final newTracking = !_tracking;
    setState(() => _tracking = newTracking);

    if (newTracking) {
      try {
        final position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
        );
        if (mounted) {
          _isAnimating = true;
          await mapboxMap?.flyTo(
            CameraOptions(
              zoom: 15,
              center: Point(
                  coordinates: Position(position.longitude, position.latitude)),
            ),
            MapAnimationOptions(duration: 500),
          );
          if (mounted) _isAnimating = false;
        }
        _locationSubscription = geo.Geolocator.getPositionStream(
          locationSettings:
              const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
        ).listen((pos) {
          if (_tracking) {
            _isAnimating = true;
            mapboxMap
                ?.flyTo(
              CameraOptions(
                center: Point(
                    coordinates: Position(pos.longitude, pos.latitude)),
              ),
              MapAnimationOptions(duration: 500),
            )
                .then((_) {
              if (mounted) _isAnimating = false;
            });
          }
        });
      } catch (_) {
        if (mounted) setState(() => _tracking = false);
      }
    } else {
      _locationSubscription?.cancel();
      _locationSubscription = null;
    }
  }

  void _onCameraChanged(CameraChangedEventData _) {
    if (!_pitchButtonActive || _isAnimating || !mounted) return;
    if (DateTime.now().isBefore(_pitchSettleUntil)) return;
    mapboxMap?.getCameraState().then((state) {
      if (!mounted || _isAnimating || !_pitchButtonActive) return;
      if (DateTime.now().isBefore(_pitchSettleUntil)) return;
      if ((state.pitch - 45.0).abs() > 2.0) {
        setState(() => _pitchButtonActive = false);
      }
    });
  }

  Future<void> _togglePitch() async {
    if (mapboxMap == null) return;
    final newActive = !_pitchButtonActive;
    if (newActive) {
      _pitchSettleUntil = DateTime.now().add(const Duration(milliseconds: 800));
    }
    setState(() => _pitchButtonActive = newActive);
    _isAnimating = true;
    try {
      await mapboxMap!.flyTo(
        CameraOptions(pitch: newActive ? 45.0 : 0.0),
        MapAnimationOptions(duration: 500),
      );
    } finally {
      if (mounted) _isAnimating = false;
    }
  }

  void _onFeatureSelected(dynamic geojsonFeature) {
    final wasVisible = _panelVisible;
    setState(() {
      selectedFeature = geojsonFeature;
      _panelVisible = true;
    });
    if (!wasVisible) {
      // Panel just added to the tree — wait one frame for it to attach
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animatePanelToDefault();
      });
    } else {
      _animatePanelToDefault();
    }
  }

  void _animatePanelToDefault() {
    final screenHeight = MediaQuery.of(context).size.height;
    final defaultPos = ((screenHeight * 0.40) - 106) / (_maxPanelHeight - 106);
    _pc.animatePanelToPosition(defaultPos.clamp(0.0, 1.0));
  }

  void _closePanel() {
    setState(() {
      selectedFeature = null;
      _panelVisible = false;
      _panelExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<void>(
      future: ImageLoader.instance.images,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading images'));
        } else {
          return buildMapContent();
        }
      },
    );
  }

  Widget buildMapContent() {
    return LayoutBuilder(builder: (context, constraints) {
      return _buildMapStack(context, constraints);
    });
  }

  Widget _buildMapStack(BuildContext context, BoxConstraints constraints) {
    final mq = MediaQuery.of(context);
    // Use actual available height (excludes bottom nav bar) and physical top
    // inset (viewPadding.top is never consumed by Scaffold, unlike padding.top)
    final double availableHeight = constraints.maxHeight;
    final double maxHeight = (availableHeight - mq.viewPadding.top - 8)
        .clamp(availableHeight * 0.85, availableHeight * 0.97);
    _maxPanelHeight = maxHeight; // cache for _animatePanelToDefault

    // Intermediate snap at 40% of screen height (relative to min/max range)
    final double snapPoint40 =
        ((mq.size.height * 0.40) - 106) / (maxHeight - 106);

    return Stack(
      children: <Widget>[
        MapHandler(
          selectedFeature: selectedFeature,
          onFeatureSelected: _onFeatureSelected,
          onMapCreated: _onMapCreated,
          parkImage: ImageLoader.instance.parkImage,
          wpaaImage: ImageLoader.instance.wpaaImage,
          popsImage: ImageLoader.instance.popsImage,
          plazaImage: ImageLoader.instance.plazaImage,
          stpImage: ImageLoader.instance.stpImage,
          miscImage: ImageLoader.instance.miscImage,
          markerFeature: markerFeature,
          onCameraChangeListener: _onCameraChanged,
        ),
        _buildBottomInfoPanel(),
        // Scrim — fades in when panel is fully expanded
        if (_panelVisible)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _panelExpanded ? 0.45 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const IgnorePointer(
                child: ColoredBox(color: Colors.black),
              ),
            ),
          ),
        // Map control buttons — midway on right side
        Positioned(
          right: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: SafeArea(
              child: MapControls(
                tracking: _tracking,
                pitchActive: _pitchButtonActive,
                onToggleTracking: _toggleTracking,
                onTogglePitch: _togglePitch,
              ),
            ),
          ),
        ),
        // Sliding panel — only in the tree when a feature is selected.
        // minHeight:106 prevents dragging below peek; X is the only dismiss.
        if (_panelVisible)
          SlidingUpPanel(
            controller: _pc,
            isDraggable: true,
            snapPoint: snapPoint40,
            panelSnapping: true,
            minHeight: 106,
            maxHeight: maxHeight,
            onPanelSlide: (pos) {
              final expanded = pos > 0.85;
              if (expanded != _panelExpanded && mounted) {
                setState(() => _panelExpanded = expanded);
              }
            },
            panel: _buildSlidingPanelContent(),
            body: Container(),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18.0)),
          ),
        if (!_panelExpanded)
          SearchWidget(
            onRetrieve: (feature) => _setMarkerFeature(feature),
            onLocalResultSelected: (feature) => _onLocalResultSelected(feature),
          ),
      ],
    );
  } // end _buildMapStack

  Widget _buildBottomInfoPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: const Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'NYC Public Space',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tap a marker to learn more or get directions',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray,
                    ),
                  ),
                  // SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlidingPanelContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Stack(
        children: <Widget>[
          const Column(
            children: [SizedBox(height: 8.0)],
          ),
          PanelHandler(
            selectedFeature: selectedFeature,
            onClosePanel: _closePanel,
            isExpanded: _panelExpanded,
          ),
        ],
      ),
    );
  }

}
