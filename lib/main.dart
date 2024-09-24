import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:flutter_futz/map_handler.dart';
import 'package:flutter_futz/panel_handler.dart';
import 'package:flutter_futz/search_handler.dart';

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Pass your access token to MapboxOptions so you can load a map
  String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  print('foo');
  print(accessToken);
  MapboxOptions.setAccessToken(accessToken);

  runApp(MyApp(accessToken: accessToken));
}

class MyApp extends StatefulWidget {
  final String accessToken;

  const MyApp({required this.accessToken, Key? key}) : super(key: key);
  @override
  State createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late final MapHandler _mapHandler;
  final PanelController _pc = PanelController();
  late final PanelHandler _panelHandler;

  @override
  void initState() {
    super.initState();

    // initialize panel handler, specify a function to run when the content is updated
    _panelHandler = PanelHandler(
      onPanelContentUpdated:
          _updatePanel, // Pass callback to handle state updates
    );

    _mapHandler = MapHandler(context);
    // Initialize map handler with panel handler functions if needed
    _mapHandler.init(_pc, _panelHandler.updatePanelContent);
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
          body: Stack(children: <Widget>[
            SlidingUpPanel(
              controller: _pc,
              panel: _panelHandler.buildPanel(),
              onPanelSlide: _panelHandler.onPanelSlide,
              body: _mapHandler.buildMap(),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18.0)),
              minHeight: 100, // The height of the collapsed panel
              maxHeight: 300, // The height of the expanded panel
            ),
            Positioned(
              top: 100, // Positioning 100 pixels from the top of the screen
              left: 16, // Optional: adds some horizontal margin
              right: 16, // Optional: adds some horizontal margin
              child: SearchInput(),
            ),
            _panelHandler.buildFloatingButton(),
          ]),
          // body:
        ));
  }
}
