import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_futz/public_space_properties.dart';

class PanelHandler {
  // initialize a variable to hold the name and type of the tapped feature
  PublicSpaceProperties _panelContent =
      PublicSpaceProperties(name: '', type: '');

  // function passed in from parent to listen for updates
  final VoidCallback? onPanelContentUpdated;

  // constructor
  PanelHandler({this.onPanelContentUpdated});

  // update the panel content
  void updatePanelContent(PublicSpaceProperties newContent) {
    _panelContent = newContent;

    // let parent component know state has been updated
    if (onPanelContentUpdated != null) {
      onPanelContentUpdated!();
    }
  }

// pill to display the type of public space
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
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 2),
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // circle
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: typeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          // label
          Text(
            typeLabel,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // panel content
  Widget buildPanel() {
    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            color:
                Colors.white.withOpacity(0.8),
            child: Column(
              children: [
                // row of pills
                Row(
                  children: [_buildPill(_panelContent.type)],
                ),
                const SizedBox(height: 8),
                // name
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _panelContent.name,
                        style: const TextStyle(
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
      child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          mini: true,
          child: Transform.translate(
            offset: const Offset(
                -1, 1),
            child: const FaIcon(
              FontAwesomeIcons.locationArrow,
              color: Colors.blue,
              size: 20.0,
            ),
          )),
    );
  }
}
