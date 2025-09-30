import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

Widget preview() {
    return SearchInput();
}

class SearchInput extends StatefulWidget {
  // map instance
  final MapboxMap? mapboxMap;

  // constructor
  const SearchInput({super.key, this.mapboxMap});

  @override
  _SearchInputState createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  // controller for text input
  final TextEditingController _controller = TextEditingController();

  // list of search results
  List<dynamic> _searchResults = [];

  late String _accessToken;

  // active selection (user has chosen a result)
  bool activeSelection = false;

  late String _sessionToken;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _resetSessionToken();
    _controller.addListener(_onSearchChanged);
    _getAccessToken();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // generate a new session token
  void _resetSessionToken() {
    _sessionToken = _uuid.v4(); // Generate a new UUID for the session
  }

  // get the Mapbox access token
  void _getAccessToken() async {
    _accessToken = await MapboxOptions.getAccessToken();
  }

  // called whenever the text in the search input changes
  void _onSearchChanged() {
    if (activeSelection) return;

    // if there is text, trigger a search, otherwise clear the search results list
    if (_controller.text.isNotEmpty) {
      _searchBoxSuggest(_controller.text);
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  // function to call the Mapbox Search Box API
  Future<void> _searchBoxSuggest(String query) async {
    final url = Uri.parse(
        'https://api.mapbox.com/search/searchbox/v1/suggest?access_token=$_accessToken&q=$query&session_token=$_sessionToken&proximity=-73.98282248131227,40.76154559516749');

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
  Future<void> _searchBoxRetrieve(String mapboxId) async {
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

        widget.mapboxMap?.flyTo(
            CameraOptions(
              center: point,
            ),
            null);

        // close the keyboard
        FocusScope.of(context).unfocus();

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
      children: [
        if (_searchResults.isNotEmpty)
        SizedBox(
          height: 400,
          child: Flexible(
            child: Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                margin: const EdgeInsets.only(
                    top: 50,
                    right: 1,
                    left: 1),
                padding: const EdgeInsets.only(
                  top: 6, 
                ),
                decoration: const BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.only(
                    bottomLeft:
                        Radius.circular(8.0), 
                    bottomRight:
                        Radius.circular(8.0), 
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4.0,
                      offset: Offset(0, 2), 
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      title: Text(
                        result['name'] ?? 'Unknown Location',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, // Make the title bold
                          fontSize: 16, // Adjust the font size as needed
                        ),
                      ),
                      subtitle: Text(
                        result['full_address'] ?? '',
                        style: const TextStyle(
                          fontSize: 12, 
                          color: Colors
                              .grey, 
                        ),
                      ),
                      onTap: () {
                        String mapboxId = result['mapbox_id'];
                        _searchBoxRetrieve(mapboxId);
                      },
                    );
                  },
                ),
              ),
            ),
          )),
        // search input with icons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              // search icon
              const FaIcon(
                FontAwesomeIcons.magnifyingGlass,
                color: Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 10),
              // text input
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search...',
                  ),
                ),
              ),
              // close button
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.xmark,
                    color: Colors.grey,
                    size: 18,
                  ),
                  onPressed: () {
                    _controller.clear();

                    setState(() {
                      activeSelection = false;
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
