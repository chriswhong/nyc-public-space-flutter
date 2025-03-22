import 'package:flutter/material.dart';
import 'package:nyc_public_space_map/colors.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:nyc_public_space_map/map_handler.dart';
import 'package:nyc_public_space_map/panel/panel_handler.dart';
// import 'package:nyc_public_space_map/search_handler.dart';
import 'package:nyc_public_space_map/image_loader.dart';
import 'package:nyc_public_space_map/floating_locator_button.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class MapScreen extends StatefulWidget {
  final Function(PublicSpaceFeature?) onReportAnIssue;

  const MapScreen({super.key, required this.onReportAnIssue});

  @override
  State createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  static const double defaultFloatingButtonOffset = 95;
  final PanelController _pc = PanelController();
  double floatingButtonOffset = defaultFloatingButtonOffset;

  MapboxMap? mapboxMap;
  PublicSpaceFeature? selectedFeature;

  User? currentUser; // Firebase User instance

  @override
  void initState() {
    super.initState();
    ImageLoader.instance.loadImages();
    _checkCurrentUser(); // Check the user's login status
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
  }

  void _onFeatureSelected(geojsonFeature) {
    _updatePanel();
    setState(() {
      selectedFeature = geojsonFeature;
    });
  }

  void _updatePanel() {
    if (_pc.isPanelClosed) {
      _pc.animatePanelToSnapPoint();
    }
  }

  void _closePanel() {
    _pc.close();
    setState(() {
      selectedFeature = null;
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
    double maxHeight = 600;

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
        ),
        _buildBottomInfoPanel(),
        SlidingUpPanel(
          controller: _pc,
          snapPoint: 0.50,
          panelSnapping: false,
          onPanelSlide: (position) {
            setState(() {
              double newPosition = (maxHeight * position) + 20;
              floatingButtonOffset = newPosition < defaultFloatingButtonOffset
                  ? defaultFloatingButtonOffset
                  : newPosition;
            });
          },
          panel: _buildSlidingPanelContent(),
          body: Container(),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18.0)),
          minHeight: 0,
          maxHeight: maxHeight,
        ),
        _buildFloatingLocatorButton(),
      ],
    );
  }

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
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingLocatorButton() {
    return Positioned(
      bottom: floatingButtonOffset,
      right: 16,
      child: FloatingLocatorButton(mapboxMap: mapboxMap),
    );
  }
}
