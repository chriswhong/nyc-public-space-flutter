import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PanelHandler {
  String _panelContent = '';
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
  void updatePanelContent(String newContent) {
    _panelContent = newContent;
    triggerStateUpdate();
  }

  // Panel Slide Listener
  void onPanelSlide(double position) {
    _fabHeight =
        _closedFabPosition + (_openFabPosition - _closedFabPosition) * position;
    triggerStateUpdate();
  }

  // Build Sliding Panel
  Widget buildPanel() {
    return Center(
      child: Text(
        _panelContent,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  // Build Floating Action Button
  Widget buildFloatingButton() {
    return Positioned(
      right: 20.0,
      bottom: _fabHeight,
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        child: const FaIcon(
          FontAwesomeIcons.locationArrow,
          color: Colors.blue,
        ),
      ),
    );
  }
}
