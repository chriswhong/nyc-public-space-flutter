import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_futz/public_space_properties.dart';

class PanelHandler {
  PublicSpaceProperties _panelContent =
      PublicSpaceProperties(name: '', type: '');
  double _fabHeight = 0;

  final double _closedFabPosition = 120.0;
  final double _openFabPosition = 300.0;

  // Function to update state from parent widget
  final VoidCallback? onPanelContentUpdated;

  PanelHandler({this.onPanelContentUpdated});

  void triggerStateUpdate() {
    if (onPanelContentUpdated != null) {
      onPanelContentUpdated!(); // Notify parent to update the state
    }
  }

  // Update the panel content
  void updatePanelContent(PublicSpaceProperties newContent) {
    _panelContent = newContent;
    triggerStateUpdate();
  }

  // Panel Slide Listener
  void onPanelSlide(double position) {
    _fabHeight =
        _closedFabPosition + (_openFabPosition - _closedFabPosition) * position;
    triggerStateUpdate();
  }

  Widget _buildPill(String type) {
    String typeLabel;
    Color typeColor;

    switch (type) {
      case 'pops':
        typeLabel = 'Privately Owned Public Space';
        typeColor = Color(0xAA6b82d6);
        break;
      case 'park':
        typeLabel = 'Park';
        typeColor = Color(0xAA77bb3f);
        break;
      case 'wpaa':
        typeLabel = 'Waterfront Public Access Area';
        typeColor = Color(0xAA0ad6f5);
        break;
      case 'plaza':
        typeLabel = 'Street Plaza';
        typeColor = Color(0xAAffbf47);
        break;
      // Add more cases as needed
      default:
        typeLabel = 'Unknown Type';
        typeColor = Color(0xAACCCCCC);
    }

    return Chip(
      backgroundColor: Colors.grey.shade200, // Light gray background
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Less padding
      shape: StadiumBorder(), // Ensures no border
      visualDensity: VisualDensity.compact, // Ensures minimal spacing
      side: BorderSide.none,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle on the left
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: typeColor, // Fill color for the circle
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4), // Space between the circle and text
          // Text label
          Text(
            typeLabel,
            style: TextStyle(fontSize: 12), // Smaller text
          ),
        ],
      ),
    );
  }

  // Build Sliding Panel
  Widget buildPanel() {
    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Container(
            padding: EdgeInsets.all(8.0),
            color:
                Colors.white.withOpacity(0.8), // Optional: Add background color
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row of pills above the title
                Row(
                  children: [_buildPill(_panelContent.type)],
                ),
                SizedBox(height: 8),
                // Title in bold
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _panelContent.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true, // Allows the text to wrap
                        overflow: TextOverflow.visible, // Ensures no clipping
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Floating Locator Button
  Widget buildFloatingLocatorButton() {
    return Positioned(
      top: 120.0,
      right: 15,
      // bottom: _fabHeight,
      child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.white,
          
          shape: const CircleBorder(),
          mini: true,
          child: Transform.translate(
            offset:
                const Offset(-1, 1), // Adjust the icon's position: move left and down
            child: const FaIcon(
              FontAwesomeIcons.locationArrow,
              color: Colors.blue,
              size: 20.0, // Adjust icon size to make it slightly smaller
            ),
          )),
    );
  }
}
