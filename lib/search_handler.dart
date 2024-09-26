import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class SearchInput extends StatefulWidget {
  const SearchInput({Key? key}) : super(key: key);

  @override
  _SearchInputState createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  TextEditingController _controller = TextEditingController();

  List<dynamic> _searchResults = [];

  String _accessToken = const String.fromEnvironment("ACCESS_TOKEN");

  bool activeSelection = false;

  late String _sessionToken; // Session token for tracking search sessions
  final Uuid _uuid = Uuid(); // UUID generator instance

  @override
  void initState() {
    super.initState();
    _resetSessionToken();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Generate a new session token
  void _resetSessionToken() {
    _sessionToken = _uuid.v4(); // Generate a new UUID for the session
  }

  // Called whenever the text in the search input changes
  void _onSearchChanged() {
    if (activeSelection) return;

    if (_controller.text.isNotEmpty) {
      _searchLocations(_controller.text);
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  // Function to call the Mapbox Search Box API
  Future<void> _searchLocations(String query) async {
    final url = Uri.parse(
        'https://api.mapbox.com/search/searchbox/v1/suggest?access_token=$_accessToken&q=$query&session_token=${_sessionToken}&proximity=-73.98282248131227,40.76154559516749');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['suggestions'] ?? [];
        });
      } else {
        print('Error fetching search results: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Function to call the retrieve API when a result is selected
  Future<void> _retrieveLocation(String mapboxId) async {
    final url = Uri.parse(
        'https://api.mapbox.com/search/searchbox/v1/retrieve/$mapboxId?session_token=$_sessionToken&access_token=$_accessToken');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle the retrieved data
        Point point = Point.fromJson(
            jsonDecode(jsonEncode(data['features'][0]['geometry'])));

        setState(() {
          activeSelection = true;

          _controller.text = data['features'][0]['properties']['full_address'];

          _searchResults.clear(); // Clear the search results to hide the list
        });
        // widget.mapboxMap?.flyTo(
        //     CameraOptions(
        //       center: point,
        //     ),
        //     null);

        // You can add further processing of the retrieved data here
      } else {
        print('Error retrieving location: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      // mainAxisSize: MainAxisSize.min, // Allow the column to take minimal space
      children: [
        // Display search results in a flexible list
        if (_searchResults.isNotEmpty)
          Flexible(
            child: Transform.translate(
              offset: Offset(0, -10), // Move the container upwards by 10 pixels
              child: Container(
                margin: EdgeInsets.only(
                    top: 50,
                    right: 1,
                    left: 1), // Add some space between input and results
                padding: EdgeInsets.only(
                  top: 6, // Add top padding of 10 pixels
                ),
                decoration: BoxDecoration(
                  color: Colors.white, // White background
                  borderRadius: BorderRadius.only(
                    bottomLeft:
                        Radius.circular(8.0), // Rounded bottom left corner
                    bottomRight:
                        Radius.circular(8.0), // Rounded bottom right corner
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4.0,
                      offset: Offset(0, 2), // Shadow positioning
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      title: Text(
                        result['name'] ?? 'Unknown Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Make the title bold
                          fontSize: 16, // Adjust the font size as needed
                        ),
                      ),
                      subtitle: Text(
                        result['full_address'] ?? '',
                        style: TextStyle(
                          fontSize: 12, // Make the subtitle smaller
                          color: Colors
                              .grey, // Optional: set a subtle color for the subtitle
                        ),
                      ),
                      onTap: () {
                        String mapboxId = result['mapbox_id'];
                        _retrieveLocation(mapboxId);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        // Search input with icons
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.magnifyingGlass,
                color: Colors.grey,
                size: 18,
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search...',
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.xmark,
                    color: Colors.grey,
                    size: 18,
                  ),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _searchResults.clear();
                    });
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
