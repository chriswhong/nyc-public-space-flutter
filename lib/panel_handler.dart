import 'package:flutter/material.dart';
import 'package:flutter_futz/public_space_properties.dart';

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
  late PublicSpaceProperties? _panelContent;

  @override
  void initState() {
    super.initState();
    // Initialize with an empty feature or the passed selectedFeature
    _panelContent = widget.selectedFeature?.properties;
  }

  // Update the panel when the selectedFeature changes
  @override
  void didUpdateWidget(PanelHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFeature != oldWidget.selectedFeature &&
        widget.selectedFeature != null) {
      setState(() {
        _panelContent = widget.selectedFeature!.properties;
      });
    }
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
                  children: [_buildPill(_panelContent!.type)],
                ),
                const SizedBox(height: 8),
                // Name of the selected feature
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _panelContent!.name,
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
