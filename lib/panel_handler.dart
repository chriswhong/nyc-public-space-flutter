import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

String extractDomainFromUri(Uri? uri) {
  // Define a regular expression to match the domain part of the URL
  RegExp domainRegex = RegExp(r'^(?:https?:\/\/)?(?:www\.)?([^\/]+)');

  // Use the RegExp to extract the domain
  String? domain;
  if (domainRegex.hasMatch(uri.toString())) {
    domain = domainRegex.firstMatch(uri.toString())?.group(1);
  }

  return domain ??
      'Invalid URI'; // Return the domain or 'Invalid URI' if it doesn't match
}

class PanelHandler extends StatefulWidget {
  final PublicSpaceFeature? selectedFeature; // Feature passed from parent
  final VoidCallback? onClosePanel; // Callback to close the panel
  final VoidCallback? onPanelContentUpdated; // Callback to close the panel
  final VoidCallback? onReportAnIssuePressed;

  const PanelHandler(
      {super.key,
      required this.selectedFeature,
      this.onClosePanel,
      this.onPanelContentUpdated,
      this.onReportAnIssuePressed});

  @override
  _PanelHandlerState createState() => _PanelHandlerState();
}

class _PanelHandlerState extends State<PanelHandler> {
  late PublicSpaceFeature? _panelContent;

  @override
  void initState() {
    super.initState();
    // Initialize with an empty feature or the passed selectedFeature
    _panelContent = widget.selectedFeature;
  }

  // Update the panel when the selectedFeature changes
  @override
  void didUpdateWidget(PanelHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFeature != oldWidget.selectedFeature &&
        widget.selectedFeature != null) {
      setState(() {
        _panelContent = widget.selectedFeature;
      });
    }
  }

  // Function to launch URL
  Future<void> _launchURL(url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _openMaps(
      double latitude, double longitude, BuildContext context) async {
    // Function to get the URI for Apple Maps or Google Maps
    Uri getMapLaunchUri(double latitude, double longitude,
        {bool isGoogleMaps = false}) {
      if (Platform.isAndroid) {
        // Use Google Maps URI for Android
        return Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
      } else if (Platform.isIOS) {
        // Provide both Apple Maps and Google Maps options on iOS
        if (isGoogleMaps) {
          return Uri.parse(
              'comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving');
        } else {
          return Uri.parse(
              'https://maps.apple.com/?daddr=$latitude,$longitude');
        }
      } else {
        throw Exception('Platform not supported');
      }
    }

    if (Platform.isIOS) {
      // Show a dialog to choose between Apple Maps and Google Maps
      await showDialog(
        context: context, // Ensure this is within a valid BuildContext
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Open in Maps'),
            content: Text('Which app would you like to use?'),
            actions: <Widget>[
              TextButton(
                child: Text('Apple Maps'),
                onPressed: () async {
                  final uri = getMapLaunchUri(latitude, longitude);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    throw 'Could not launch Apple Maps';
                  }
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: Text('Google Maps'),
                onPressed: () async {
                  final uri =
                      getMapLaunchUri(latitude, longitude, isGoogleMaps: true);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    throw 'Could not launch Google Maps';
                  }
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
    } else if (Platform.isAndroid) {
      // Directly launch Google Maps on Android
      final uri = getMapLaunchUri(latitude, longitude);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback if Google Maps is not available
        throw 'Could not launch Google Maps';
      }
    }
  }

  Widget _lightDivider() {
    return Divider(
      color: const Color.fromARGB(255, 204, 204, 204), // Color of the line
      thickness: 0.5, // Thickness of the line
    );
  }

  // Method to build a pill showing the type of public space
  Widget _buildPill(String type) {
    String typeLabel;
    Color typeColor;

    switch (type) {
      case 'pops':
        typeLabel = 'Privately Owned Public Space';
        typeColor = const Color(0xAA6b82d6);
        break;
      case 'park':
        typeLabel = 'Park';
        typeColor = const Color(0xAA77bb3f);
        break;
      case 'wpaa':
        typeLabel = 'Waterfront Public Access Area';
        typeColor = const Color(0xAA0ad6f5);
        break;
      case 'plaza':
        typeLabel = 'Street Plaza';
        typeColor = const Color(0xAAffbf47);
        break;
      case 'stp':
        typeLabel = 'Schoolyards to Playgrounds';
        typeColor = const Color(0xAAF55353);
        break;
      default:
        typeLabel = 'Miscellaneous';
        typeColor = const Color(0xAACCCCCC);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: typeColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          typeLabel,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // If _panelContent is null, don't render the panel content
    if (_panelContent == null) {
      return const SizedBox.shrink(); // Return an empty widget
    }
    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white.withOpacity(0.8),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // This ensures the Column takes only necessary space
              children: [
                // Name of the selected feature
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                            maxWidth:
                                screenWidth - 75), // Set your desired max width
                        child: Text(
                          _panelContent!.properties.name ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          softWrap: true, // Allows the text to wrap
                          overflow: TextOverflow.visible, // Ensures no clipping
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row of pills
                Row(
                  children: [_buildPill(_panelContent!.properties.type)],
                ),
                const SizedBox(height: 8),
                // Location text
                // Row(
                //   children: [
                //     Flexible(
                //       child: Text(
                //         _panelContent!.properties.location ?? '',
                //         style: const TextStyle(
                //           fontSize: 14,
                //           fontWeight: FontWeight.normal,
                //         ),
                //         softWrap: true, // Allows the text to wrap
                //         overflow: TextOverflow.visible, // Ensures no clipping
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 8),
                Padding(
                  padding:
                      const EdgeInsets.all(8.0), // Add padding around the row
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceEvenly, // Evenly space the buttons
                    children: [
                      // First button for "Get Directions"
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300], // Light gray background
                              shape: BoxShape.circle, // Circular shape
                            ),
                            child: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons
                                    .diamondTurnRight, // Navigation icon
                                size: 20, // Icon size
                                color: Colors.grey[800], // Dark gray icon
                              ),
                              onPressed: () {
                                _openMaps(
                                  (_panelContent!.geometry.coordinates.lat)
                                      .toDouble(),
                                  (_panelContent!.geometry.coordinates.lng)
                                      .toDouble(),
                                  context,
                                );
                              },
                              tooltip: 'Open in Maps',
                            ),
                          ),
                          const SizedBox(
                              height: 4), // Space between icon and text
                          const Text(
                            'Open in Maps',
                            style: TextStyle(fontSize: 12), // Small text label
                          ),
                        ],
                      ),
                      SizedBox(width: 10),
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300], // Light gray background
                              shape: BoxShape.circle, // Circular shape
                            ),
                            child: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons
                                    .triangleExclamation, // Navigation icon
                                size: 20, // Icon size
                                color: Colors.grey[800], // Dark gray icon
                              ),
                              onPressed: () {
                                widget.onReportAnIssuePressed!();
                              },
                              tooltip: 'Report an Issue',
                            ),
                          ),
                          const SizedBox(
                              height: 4), // Space between icon and text
                          const Text(
                            'Report an Issue',
                            style: TextStyle(fontSize: 12), // Small text label
                          ),
                        ],
                      ),
                      // Second button for "More Info"
                      // if (_panelContent != null && _panelContent!.properties.url != null)
                      //   Column(
                      //     children: [
                      //       Container(
                      //         decoration: BoxDecoration(
                      //           color: Colors.grey[300], // Light gray background
                      //           shape: BoxShape.circle, // Circular shape
                      //         ),
                      //         child: IconButton(
                      //           icon: FaIcon(
                      //             FontAwesomeIcons.infoCircle, // Web info icon
                      //             size: 20, // Icon size
                      //             color: Colors.grey[800], // Dark gray icon
                      //           ),
                      //           onPressed: () {
                      //             _launchURL(_panelContent!.properties.url);
                      //           },
                      //           tooltip: 'Website',
                      //         ),
                      //       ),
                      //       const SizedBox(height: 4), // Space between icon and text
                      //       const Text(
                      //         'Website',
                      //         style: TextStyle(fontSize: 12), // Small text label
                      //       ),
                      //     ],
                      //   ),
                    ],
                  ),
                ),
                _lightDivider(),
                _panelContent != null &&
                        _panelContent!.properties.description != null &&
                        _panelContent!.properties.description?.isNotEmpty ==
                            true
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(_panelContent!.properties.description!),
                          _lightDivider(), // Add the additional widget here
                        ],
                      )
                    : SizedBox.shrink(),
                _panelContent != null &&
                        _panelContent!.properties.location != null &&
                        _panelContent!.properties.location?.isNotEmpty == true
                    ? Column(
                        children: [
                          SizedBox(height: 4),
                          ListTile(
                            leading:
                                FaIcon(FontAwesomeIcons.mapMarkerAlt, size: 18),

                            title: Text(
                                _panelContent!.properties.location ??
                                    'Address not available',
                                style: TextStyle(fontSize: 14)),
                            visualDensity: VisualDensity(
                                vertical: -4), // Reduce vertical space
                          ),
                          _lightDivider(),
                        ],
                      )
                    : SizedBox.shrink(),
                _panelContent != null && _panelContent!.properties.url != null
                    ? Column(
                        children: [
                          SizedBox(height: 4),
                          ListTile(
                            leading: FaIcon(FontAwesomeIcons.link, size: 18),

                            title: Text(
                                extractDomainFromUri(
                                    _panelContent!.properties.url),
                                style: TextStyle(fontSize: 14)),
                            visualDensity: VisualDensity(
                                vertical: -4), // Reduce vertical space

                            onTap: () {
                              _launchURL(_panelContent!.properties.url);
                            },
                          ),
                          _lightDivider(),
                        ],
                      )
                    : SizedBox.shrink(),
              ],
            ),
          ),
        ),
        // Add close button in the top-right corner
        Positioned(
          right: 10,
          top: 10,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed:
                widget.onClosePanel, // Call the close function when tapped
          ),
        ),
      ],
    );
  }
}
