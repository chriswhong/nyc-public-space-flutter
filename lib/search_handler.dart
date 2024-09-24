import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchInput extends StatefulWidget {
  @override
  _SearchInputState createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  TextEditingController _controller = TextEditingController();
  List<dynamic> _searchResults = [];
  String _accessToken = const String.fromEnvironment("ACCESS_TOKEN");

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Called whenever the text in the search input changes
  void _onSearchChanged() {
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
        'https://api.mapbox.com/search/searchbox/v1/suggest?access_token=$_accessToken&query=$query&limit=5');

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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Allow the column to take minimal space
      children: [
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
        // Display search results in a flexible list
        if (_searchResults.isNotEmpty)
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  title: Text(result['name'] ?? 'Unknown Location'),
                  subtitle: Text(result['description'] ?? ''),
                  onTap: () {
                    print('Selected: ${result['name']}');
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
