import 'package:flutter/material.dart';
import 'package:flutter_futz/public_space_properties.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:flutter_futz/map_handler.dart';
import 'package:flutter_futz/panel_handler.dart';
import 'package:flutter_futz/search_handler.dart';
import 'package:flutter_futz/image_loader.dart';
import 'package:flutter_futz/floating_locator_button.dart';

class MapScreen extends StatefulWidget {
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
    _pc.animatePanelToSnapPoint();
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
      body: FutureBuilder<void>(
        future: ImageLoader.instance.images,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // show loading indicator while images are loading
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading images'));
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
    double minHeight = screenHeight * 0.2;
    double maxHeight = screenHeight * 0.7;

    return Stack(children: <Widget>[
      // map and panel
      SlidingUpPanel(
        controller: _pc,
        snapPoint: 0.3,
        panel: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
            child: Stack(children: <Widget>[
              Column(
                children: [
                  // Add the drag handle here
                  SizedBox(
                    height: 12.0,
                  ),
                  Center(
                    child: Container(
                      width: 40.0,
                      height: 5.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
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
        body: MapHandler(
          selectedFeature: selectedFeature,
          onFeatureSelected: _onFeatureSelected,
          onMapCreated: _onMapCreated,
          parkImage: ImageLoader.instance.parkImage,
          wpaaImage: ImageLoader.instance.wpaaImage,
          popsImage: ImageLoader.instance.popsImage,
          plazaImage: ImageLoader.instance.plazaImage,
        ),
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
      FloatingLocatorButton(
        mapboxMap: mapboxMap
      ),
    ]);
  }
}
