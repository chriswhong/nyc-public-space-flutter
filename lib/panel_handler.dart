import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_futz/public_space_properties.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

class PanelHandler extends StatefulWidget {
  final PublicSpaceFeature? selectedFeature; // Feature passed from parent
  final VoidCallback? onClosePanel; // Callback to close the panel
  final VoidCallback? onPanelContentUpdated; // Callback to close the panel

  const PanelHandler({
    Key? key,
    required this.selectedFeature,
    this.onPanelContentUpdated,
    this.onClosePanel,
  }) : super(key: key);

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

  // Function to open Apple Maps with navigation to the provided latitude and longitude
  Future<void> _openAppleMaps(double latitude, double longitude) async {
    Uri getMapLaunchUri(double latitude, double longitude) {
    if (Platform.isAndroid) {
      return Uri.parse('geo:$latitude,$longitude');
    } else if (Platform.isIOS) {
      return Uri.parse('https://maps.apple.com/?daddr=$latitude,$longitude');
    } else {
      throw Exception('Platform not supported');
    }
  }

  final uri = getMapLaunchUri(latitude, longitude);
      await launchUrl(uri, mode: LaunchMode.externalApplication);

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
      default:
        typeLabel = 'Unknown Type';
        typeColor = const Color(0xAACCCCCC);
    }

    return Chip(
      backgroundColor: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      label: Row(
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
          const SizedBox(width: 4),
          Text(
            typeLabel,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Panel content widget
  @override
  Widget build(BuildContext context) {
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
              children: [
                // Row of pills
                Row(
                  children: [_buildPill(_panelContent!.properties.type)],
                ),
                const SizedBox(height: 8),
                // Name of the selected feature
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _panelContent!.properties.name ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true, // Allows the text to wrap
                        overflow: TextOverflow.visible, // Ensures no clipping
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _panelContent!.properties.location ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        softWrap: true, // Allows the text to wrap
                        overflow: TextOverflow.visible, // Ensures no clipping
                      ),
                    ),
                  ],
                ),
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
                                    .locationArrow, // Navigation icon
                                size: 20, // Icon size
                                color: Colors.grey[800], // Dark gray icon
                              ),
                              onPressed: () {
                                _openAppleMaps(
                                    (_panelContent!.geometry.coordinates.lat)
                                        .toDouble(),
                                    (_panelContent!.geometry.coordinates.lng)
                                        .toDouble());
                              },
                              tooltip: 'Get Directions',
                            ),
                          ),
                          SizedBox(height: 4), // Space between icon and text
                          Text(
                            'Get Directions',
                            style: TextStyle(fontSize: 12), // Small text label
                          ),
                        ],
                      ),

                      // Second button for "More Info"
                      if (_panelContent != null &&
                          _panelContent!.properties.url != null)
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    Colors.grey[300], // Light gray background
                                shape: BoxShape.circle, // Circular shape
                              ),
                              child: IconButton(
                                icon: FaIcon(
                                  FontAwesomeIcons.infoCircle, // Web info icon
                                  size: 20, // Icon size
                                  color: Colors.grey[800], // Dark gray icon
                                ),
                                onPressed: () {
                                  _launchURL(_panelContent!.properties.url);
                                },
                                tooltip: 'More Info',
                              ),
                            ),
                            SizedBox(height: 4), // Space between icon and text
                            Text(
                              'More Info',
                              style:
                                  TextStyle(fontSize: 12), // Small text label
                            ),
                          ],
                        ),
                    ],
                  ),
                )
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
