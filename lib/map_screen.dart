import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:nyc_public_space_map/map_handler.dart';
import 'package:nyc_public_space_map/panel_handler.dart';
import 'package:nyc_public_space_map/search_handler.dart';
import 'package:nyc_public_space_map/image_loader.dart';
import 'package:nyc_public_space_map/floating_locator_button.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:nyc_public_space_map/side_drawer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final PanelController _pc = PanelController();

  // map instance
  MapboxMap? mapboxMap;
  // selected feature
  PublicSpaceFeature? selectedFeature;

  // passed into MapHandler, sets map instance after the map is created
  void _onMapCreated(MapboxMap mapInstance) {
    setState(() {
      mapboxMap = mapInstance;
    });
  }

  @override
  void initState() {
    super.initState();

    ImageLoader.instance.loadImages();
  }

  void _onFeatureSelected(geojsonFeature) {
    _updatePanel();
    setState(() {
      selectedFeature = geojsonFeature;
    });
  }

  // callback to trigger a rebuild when content changes
  void _updatePanel() {
    if (_pc.isPanelClosed) {
      _pc.animatePanelToSnapPoint();
    }
    // setState(() {});
  }

  // callback to trigger a rebuild when content changes
  void _closePanel() {
    _pc.close();
    setState(() {
      selectedFeature = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideDrawer(),
      body: FutureBuilder<void>(
        future: ImageLoader.instance.images,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // show loading indicator while images are loading
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading images'));
          } else {
            return buildMapContent(context);
          }
        },
      ),

      // body:
    );
  }

  Widget buildMapContent(BuildContext context) {
    // calculate min and max height for panel
    double screenHeight = MediaQuery.of(context).size.height;
    // double minHeight = screenHeight * 0.3;
    double maxHeight = 600;

    return Stack(children: <Widget>[
      // map and panel
      MapHandler(
          selectedFeature: selectedFeature,
          onFeatureSelected: _onFeatureSelected,
          onMapCreated: _onMapCreated,
          parkImage: ImageLoader.instance.parkImage,
          wpaaImage: ImageLoader.instance.wpaaImage,
          popsImage: ImageLoader.instance.popsImage,
          plazaImage: ImageLoader.instance.plazaImage,
          stpImage: ImageLoader.instance.stpImage,
          miscImage: ImageLoader.instance.miscImage),

      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
            width: double.infinity, // Full width
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.0)), // Rounded top corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Adjust height to content
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'NYC Public Spaces',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tap a marker to learn more or get directions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Add additional content here if needed
                  ],
                ),
              ),
              SizedBox(
                width: 50, // Fixed width
                // color: Colors.red,
                height: 50, // Same height as the left widget
                child: Align(
                  alignment:
                      Alignment.topCenter, // Aligns content to the top center
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Light gray background
                      shape: BoxShape.circle, // Circular shape
                    ),
                    child: IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.bars, // Navigation icon
                        size: 20, // Icon size
                        color: Colors.grey[800], // Dark gray icon
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ),
              ),
            ])),
      ),
      SlidingUpPanel(
        controller: _pc,
        snapPoint: 0.50,
        panelSnapping: false,
        panel: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
            child: Stack(children: <Widget>[
              const Column(
                children: [
                  // // Add the drag handle here
                  // SizedBox(
                  //   height: 12.0,
                  // ),
                  // Center(
                  //   child: Container(
                  //     width: 40.0,
                  //     height: 5.0,
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey[300],
                  //       borderRadius: BorderRadius.circular(12.0),
                  //     ),
                  //   ),
                  // ),
                  SizedBox(
                    height: 8.0,
                  ),
                ],
              ),
              PanelHandler(
                  selectedFeature: selectedFeature,
                  onPanelContentUpdated: _updatePanel,
                  onClosePanel: _closePanel)
            ])),
        body: Container(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18.0)),
        minHeight: 0,
        maxHeight: maxHeight,
      ),
      // search widget, disabled for now
      // if (mapboxMap != null) ...[
      //   Positioned(
      //     top: 56,
      //     left: 16,
      //     right: 16,
      //     child: SearchInput(mapboxMap: mapboxMap),
      //   ),
      // ],
      // locator button
      FloatingLocatorButton(mapboxMap: mapboxMap),
    ]);
  }
}
