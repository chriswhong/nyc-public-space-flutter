import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:nyc_public_space_map/geojson_provider.dart' as geo;

class SearchWidget extends StatefulWidget {
  final Function(Feature?) onRetrieve;
  final Function(PublicSpaceFeature?) onLocalResultSelected;

  const SearchWidget({super.key, required this.onRetrieve, required this.onLocalResultSelected});

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  bool isExpanded = false;
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();

  List<dynamic> _searchResults = [];
  List<dynamic> _localSearchResults = [];
  List<Map<String, String>> _recentSearches = [];
  late String _accessToken;

  late String _sessionToken;
  final Uuid _uuid = const Uuid();

  int? _selectedIndex;
  String? _lastSearchResult; // Track the last search result text
  Feature? _lastMarkerFeature; // Track the last marker feature

  void toggleSearch() {
    setState(() {
      if (isExpanded) {
        _focusNode.unfocus();
        isExpanded = false;
        // Restore the last search result text and marker when closing search
        if (_lastSearchResult != null) {
          _controller.text = _lastSearchResult!;
        }
        if (_lastMarkerFeature != null) {
          widget.onRetrieve(_lastMarkerFeature);
        }
      } else {
        _focusNode.requestFocus();
        isExpanded = true;
      }
    });
  }

  // called whenever the text in the search input changes
  void _onSearchChanged() {
    // Only call API if there is text and the input is not empty
    final value = _controller.text;
    if (value.isNotEmpty) {
      // Clear marker when starting a new search (typing)
      widget.onRetrieve(null);
      _searchBoxSuggest(value);
      _localFuzzySearch(value);
    }
    // Do NOT call _searchBoxSuggest if input is empty
    // Do NOT clear _searchResults here, let onChanged handle it
  }

  void _localFuzzySearch(String query) {
    final geoJsonProvider = Provider.of<geo.GeoJsonProvider>(context, listen: false);
    final features = geoJsonProvider.features;


    // Convert features to List<Map<String, dynamic>> for Fuzzy
    final featureMaps = features.map((f) => f.toMap()).toList();

    final fuse = Fuzzy<Map<String, dynamic>>(
      featureMaps,
      options: FuzzyOptions<Map<String, dynamic>>(
        keys: [
          WeightedKey<Map<String, dynamic>>(
            name: 'properties.name',
            getter: (item) => item['properties']?['name'] ?? '',
            weight: 1,
          ),
          // WeightedKey<Map<String, dynamic>>(
          //   name: 'properties.location',
          //   getter: (item) => item['properties']?['location'] ?? '',
          //   weight: 1,
          // ),
        ],
        threshold: 0.2, // Lower threshold for stricter matching
      ),
    );
    final results = fuse.search(query);
    
    setState(() {
      _localSearchResults = results.take(5).map((r) => r.item).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        isExpanded = _focusNode.hasFocus;
      });
    });
    _resetSessionToken();
    _getAccessToken();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    List<Map<String, String>> parsed = [];
    for (final s in searches) {
      final parts = s.split('|');
      parsed.add({
        'name': parts[0],
        'mapbox_id': parts.length > 1 ? parts[1] : '',
      });
    }
    setState(() {
      _recentSearches = parsed;
    });
  }

  Future<void> _saveRecentSearch(String name, String mapboxId) async {
    if (name.trim().isEmpty || mapboxId.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, String>> searches = List.from(_recentSearches);
    searches.removeWhere((s) => s['mapbox_id'] == mapboxId);
    searches.insert(0, {'name': name, 'mapbox_id': mapboxId});
    if (searches.length > 10) {
      searches = searches.take(10).toList();
    }
    final searchStrings = searches.map((s) => '${s['name']}|${s['mapbox_id']}').toList();
    await prefs.setStringList('recent_searches', searchStrings);
    setState(() {
      _recentSearches = searches;
    });
  }

  void _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches = [];
    });
  }

  void _selectRecentSearch(Map<String, String> search) async {
    _controller.text = search['name'] ?? '';
    final geoJsonProvider = Provider.of<geo.GeoJsonProvider>(context, listen: false);
    PublicSpaceFeature? localFeature;
    if (geoJsonProvider.features.isEmpty) {
      localFeature = null;
    } else {
      final matches = geoJsonProvider.features.where(
        (f) => f.properties.firestoreId.toString() == search['mapbox_id'],
      );
      localFeature = matches.isNotEmpty ? matches.first : null;
    }
    if (localFeature != null) {
      // Mimic the same logic as selecting a local result in search results
      final data = localFeature.toMap();
      final name = data['properties']?['name'] ?? '';
      final mapboxId = data['properties']?['firestoreId']?.toString() ?? name;
      await _saveRecentSearch(name, mapboxId);
      toggleSearch();
      final properties = data['properties'];
      properties['details'] = jsonEncode(properties['details'] ?? []);
      properties['amenities'] = jsonEncode(properties['amenities'] ?? []);
      properties['equipment'] = jsonEncode(properties['equipment'] ?? []);
      widget.onLocalResultSelected(
        PublicSpaceFeature.fromJson({
          'type': 'misc',
          'geometry': data['geometry'],
          'properties': properties,
        }),
      );
      return;
    }
    // Otherwise, treat as remote (Mapbox) result
    if (search['mapbox_id'] != null && search['mapbox_id']!.isNotEmpty) {
      toggleSearch();
      await _searchBoxRetrieve(search['mapbox_id']!);
    }
  }

  // generate a new session token
  void _resetSessionToken() {
    _sessionToken = _uuid.v4(); // Generate a new UUID for the session
  }

  // get the Mapbox access token
  void _getAccessToken() async {
    _accessToken = await MapboxOptions.getAccessToken();
  }

  // function to call the Mapbox Search Box API
  Future<void> _searchBoxSuggest(String query) async {
    if (query.trim().isEmpty) return; // Prevent API call if query is empty
    final url = Uri.parse(
        'https://api.mapbox.com/search/searchbox/v1/suggest?bbox=-74.45205591458686%2C40.42596822073202%2C-73.41863685048045%2C41.02030357662383&access_token=$_accessToken&q=$query&session_token=$_sessionToken&proximity=-73.98282248131227,40.76154559516749');

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

  Future<void> _searchBoxRetrieve(String mapboxId) async {
    final url = Uri.parse(
      'https://api.mapbox.com/search/searchbox/v1/retrieve/$mapboxId?access_token=$_accessToken&session_token=$_sessionToken',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final featureMap = data['features'][0] as Map<String, dynamic>;

        final feature = Feature.fromJson(featureMap);

        final searchText = feature.properties?['name_preferred'] ?? '';
        _controller.text = searchText;
        _lastSearchResult = searchText; // Save the search result text
        _lastMarkerFeature = feature; // Save the marker feature

        // Save to recent searches with name and mapboxId
        await _saveRecentSearch(searchText, mapboxId);

        widget.onRetrieve(feature);

       
      } else {
        print('Failed to retrieve place: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving place: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine both search results
    final combinedResults = [
      ..._localSearchResults.map((r) => {'type': 'local', 'data': r}),
      ..._searchResults.map((r) => {'type': 'remote', 'data': r}),
    ];

    // Helper functions for extracting properties
    String getLocalName(dynamic result) =>
        result['properties']?['name'] ?? 'Unknown Location';
    String getLocalAddress(dynamic result) =>
        result['properties']?['location'] ?? '';
    String getLocalMapboxId(dynamic result) =>
        result['properties']?['mapbox_id'] ?? '';
    String getLocalType(dynamic result) =>
        result['properties']?['type'] ?? 'default';

    Widget localMarkerIcon(dynamic result) {
      final type = getLocalType(result);
      final assetPath = 'assets/$type.png';
      return Image.asset(
        assetPath,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
      );
    }

    String getRemoteName(dynamic result) =>
        result['name'] ?? 'Unknown Location';
    String getRemoteAddress(dynamic result) =>
        result['full_address'] ?? '';
    String getRemoteMapboxId(dynamic result) =>
        result['mapbox_id'] ?? '';

    return Stack(
      children: [
        AnimatedOpacity(
          duration: Duration(milliseconds: 100),
          opacity: isExpanded ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !isExpanded,
            child: Container(
                color: Colors.white,
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: [
                    if (combinedResults.isNotEmpty)
                      Flexible(
                        child: Transform.translate(
                          offset: const Offset(0, 90),
                          child: Container(
                            margin: const EdgeInsets.only(
                                top: 50, right: 1, left: 1),
                            padding: const EdgeInsets.only(
                              top: 6,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8.0),
                                bottomRight: Radius.circular(8.0),
                              ),
                            ),
                            child: SearchResultsList(
                              results: combinedResults,
                              selectedIndex: _selectedIndex,
                              onTap: (index) async {
                                setState(() {
                                  _selectedIndex = index;
                                });
                                final result = combinedResults[index];
                                if (result['type'] == 'local') {
                                  final data = result['data'];
                                  final name = getLocalName(data);
                                  final mapboxId = data['properties']?['firestoreId']?.toString()
                                    ?? getLocalMapboxId(data)
                                    ?? name;
                                  await _saveRecentSearch(name, mapboxId);
                                  _controller.text = name; // Set the text in search input
                                  _lastSearchResult = name; // Save the search result text
                                  _lastMarkerFeature = null; // Clear any previous mapbox marker
                                  toggleSearch();
                                  final properties = data['properties'];
                                  properties['details'] = jsonEncode(properties['details'] ?? []);
                                  properties['amenities'] = jsonEncode(properties['amenities'] ?? []);
                                  properties['equipment'] = jsonEncode(properties['equipment'] ?? []);
                                  widget.onLocalResultSelected(
                                    PublicSpaceFeature.fromJson({
                                      'type': 'misc',
                                      'geometry': data['geometry'],
                                      'properties': properties,
                                    }),
                                  );
                                } else {
                                  final data = result['data'];
                                  final mapboxId = getRemoteMapboxId(data);
                                  final name = getRemoteName(data);
                                  await _saveRecentSearch(name, mapboxId);
                                  toggleSearch();
                                  _searchBoxRetrieve(mapboxId);
                                }
                              },
                              getName: (result) => result['type'] == 'local'
                                  ? getLocalName(result['data'])
                                  : getRemoteName(result['data']),
                              getAddress: (result) => result['type'] == 'local'
                                  ? getLocalAddress(result['data'])
                                  : getRemoteAddress(result['data']),
                              getMapboxId: (result) => result['type'] == 'local'
                                  ? getLocalMapboxId(result['data'])
                                  : getRemoteMapboxId(result['data']),
                              leadingBuilder: (result) {
                                if (result['type'] == 'local') {
                                  return localMarkerIcon(result['data']);
                                } else {
                                  // Mapbox results: show a generic icon
                                  return const Icon(Icons.location_on, color: Colors.grey, size: 24);
                                }
                              },
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 150), // Move everything up by reducing top padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_recentSearches.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Recent',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _clearRecentSearches,
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              ),
                            if (_recentSearches.isNotEmpty)
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(top: 0), // Remove extra top padding
                                  itemCount: _recentSearches.length,
                                  itemBuilder: (context, index) {
                                    final search = _recentSearches[index];
                                    return ListTile(
                                      leading: const Icon(Icons.history, color: Colors.grey),
                                      title: Text(search['name'] ?? ''),
                                      onTap: () => _selectRecentSearch(search),
                                    );
                                  },
                                ),
                              ),
                            if (_recentSearches.isEmpty)
                              Center(
                                child: Text(
                                  'No recent searches',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                )),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 16, left: 16, right: 16),
            child: GestureDetector(
              onTap: toggleSearch,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height:
                    48, // Set the height of the container to match the input

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: toggleSearch,
                        child: Icon(
                          size: 18,
                          isExpanded
                              ? FontAwesomeIcons.chevronLeft
                              : FontAwesomeIcons.search,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            if (value.isEmpty) {
                              setState(() {
                                _searchResults.clear();
                              });
                            }
                            _onSearchChanged(); // <-- Call this instead of _searchBoxSuggest
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_controller.value.text.isNotEmpty) {
                            _controller.clear();
                            _lastSearchResult = null; // Clear saved search result
                            _lastMarkerFeature = null; // Clear saved marker feature
                            setState(() {
                              _searchResults.clear();
                              _localSearchResults.clear(); // <-- Clear local results too
                              _selectedIndex = null;
                            });
                            widget.onRetrieve(null);
                          }
                        },
                        child: _controller.value.text.isNotEmpty
                            ? Icon(
                                size: 18,
                                FontAwesomeIcons.close,
                                color: Colors.black,
                              )
                            : SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchResultsList extends StatelessWidget {
  final List<dynamic> results;
  final int? selectedIndex;
  final void Function(int) onTap;
  final String Function(dynamic) getName;
  final String Function(dynamic) getAddress;
  final String Function(dynamic) getMapboxId;
  final Widget Function(dynamic)? leadingBuilder; // <-- Add this

  const SearchResultsList({
    Key? key,
    required this.results,
    required this.selectedIndex,
    required this.onTap,
    required this.getName,
    required this.getAddress,
    required this.getMapboxId,
    this.leadingBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      shrinkWrap: true,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1.0,
              ),
            ),
          ),
          child: ListTile(
            leading: leadingBuilder != null ? leadingBuilder!(result) : null, // <-- Use icon builder
            title: Text(
              getName(result),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              getAddress(result),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            onTap: () => onTap(index),
          ),
        );
      },
    );
  }
}