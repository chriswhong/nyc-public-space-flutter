import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:flutter_futz/map_handler.dart';
import 'package:flutter_futz/panel_handler.dart';
import 'package:flutter_futz/search_handler.dart';
import 'package:flutter_futz/image_loader.dart';

class MapScreen extends StatefulWidget {
  @override
  State createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late final MapHandler _mapHandler;
  final PanelController _pc = PanelController();
  late final PanelHandler _panelHandler;
  MapboxMap? mapboxMap;

  // Callback function to receive the MapboxMapController from MapWidget
  void _onMapCreated(MapboxMap mapInstance) {
    setState(() {
      mapboxMap = mapInstance;
    });
  }

  @override
  void initState() {
    super.initState();

    // initialize panel handler, specify a function to run when the content is updated
    _panelHandler = PanelHandler(
      onPanelContentUpdated:
          _updatePanel, // Pass callback to handle state updates
    );

    _mapHandler = MapHandler(_onMapCreated);
    // Initialize map handler with panel handler functions if needed
    _mapHandler.init(_pc, _panelHandler.updatePanelContent);

    ImageLoader.instance.loadImages();
  }

  // Callback to trigger a rebuild when content changes
  void _updatePanel() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();

    return MaterialApp(
        title: 'Flutter Demo',
        home: Scaffold(
          body: FutureBuilder<void>(
            future: ImageLoader.instance.images, // Wait for images to load
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show loading indicator while images are loading
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                // Handle errors gracefully
                return Center(child: Text('Error loading images'));
              } else {
                // Images are loaded, pass them to MapHandler
                return buildMapContent(context);
              }
            },
          ),

          // body:
        ));
  }

  Widget buildMapContent(BuildContext context) {
    // Get the screen height using MediaQuery
    double screenHeight = MediaQuery.of(context).size.height;

    // Set minHeight and maxHeight as percentages of the screen height
    double minHeight = screenHeight * 0.2;
    double maxHeight = screenHeight * 0.7;
    return Stack(children: <Widget>[
      SlidingUpPanel(
        controller: _pc,
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
              _panelHandler.buildPanel(),
            ])),
        onPanelSlide: _panelHandler.onPanelSlide,
        body: _mapHandler.buildMap(
            parkImage: ImageLoader.instance.parkImage,
            wpaaImage: ImageLoader.instance.wpaaImage,
            popsImage: ImageLoader.instance.popsImage,
            plazaImage: ImageLoader.instance.plazaImage,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18.0)),
        minHeight: minHeight, // The height of the collapsed panel
        maxHeight: maxHeight, // The height of the expanded panel
      ),
      if (mapboxMap != null) ...[
        Positioned(
          top: 56, // Positioning 100 pixels from the top of the screen
          left: 16, // Optional: adds some horizontal margin
          right: 16, // Optional: adds some horizontal margin
          child: SearchInput(mapboxMap: mapboxMap),
        ),
      ],
      _panelHandler.buildFloatingButton(),
    ]);
  }
}
