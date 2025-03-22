import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

import '../public_space_properties.dart';
import '../submit_image.dart';
import '../editor_screen.dart';
import '../sign_in_screen.dart';
import '../attribute_display.dart';
import '../colors.dart';
import 'panel_header.dart';
import 'panel_image_gallery.dart';
import 'panel_action_buttons.dart';
import 'panel_location_section.dart';
import 'panel_link_section.dart';

class PanelHandler extends StatefulWidget {
  final PublicSpaceFeature? selectedFeature;
  final VoidCallback? onClosePanel;

  const PanelHandler(
      {super.key, required this.selectedFeature, this.onClosePanel});

  @override
  State<PanelHandler> createState() => _PanelHandlerState();
}

class _PanelHandlerState extends State<PanelHandler> {
  late PublicSpaceFeature? _panelContent;
  List<Map<String, dynamic>> imageList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _panelContent = widget.selectedFeature;
    fetchImages();
  }

  @override
  void didUpdateWidget(covariant PanelHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFeature != oldWidget.selectedFeature) {
      setState(() {
        _panelContent = widget.selectedFeature;
        _isLoading = true;
        imageList = [];
      });
      fetchImages();
    }
  }

  Future<void> fetchImages() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('images')
          .where('spaceId',
              isEqualTo: widget.selectedFeature?.properties.firestoreId)
          .where('status', isNotEqualTo: 'rejected')
          .orderBy('timestamp', descending: false)
          .get();

      List<Map<String, dynamic>> imageListUpdate = [];
      for (var doc in querySnapshot.docs) {
        final filename = doc['filename'];
        final spaceId = doc['spaceId'];
        final status = doc['status'];
        final username = doc['username'];
        final timestamp = doc['timestamp'];

        final thumbnailUrl =
            await _getDownloadUrl(spaceId, 'thumbnail', filename);
        final mediumUrl = await _getDownloadUrl(spaceId, 'medium', filename);

        imageListUpdate.add({
          'thumbnailUrl': thumbnailUrl,
          'mediumUrl': mediumUrl,
          'status': status,
          'username': username,
          'timestamp': timestamp
        });
      }

      setState(() {
        imageList = imageListUpdate;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching images: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getDownloadUrl(
      String spaceId, String size, String filename) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('spaces_images/$spaceId/$size/$filename');
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting $size URL: $e');
      return '';
    }
  }

  void _handleClosePanel() {
    widget.onClosePanel?.call();
    setState(() {
      _isLoading = true;
      imageList = [];
    });
  }

  void _handleAddPhoto() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoSubmissionScreen(
            spaceId: _panelContent!.properties.firestoreId,
            onSubmissionComplete: fetchImages,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }

  void _handleEdit() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditorScreen(selectedFeature: _panelContent),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }

  void _handleOpenMaps() {
    final lat = _panelContent!.geometry.coordinates.lat.toDouble();
    final lng = _panelContent!.geometry.coordinates.lng.toDouble();
    final uri = Platform.isIOS
        ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lng')
        : Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    if (_panelContent == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: PanelHeader(
                    name: _panelContent!.properties.name ?? '',
                    type: _panelContent!.properties.type,
                  ),
                ),
                const Divider(color: AppColors.gray, thickness: 0.5),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_panelContent!.properties.description?.isNotEmpty ==
                            true)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(_panelContent!.properties.description!),
                          ),
                        PanelImageGallery(
                          imageList: imageList,
                          isLoading: _isLoading,
                          onAddPhoto: _handleAddPhoto,
                        ),
                        PanelActionButtons(
                          onOpenMaps: _handleOpenMaps,
                          onEdit: _handleEdit,
                          onSubmitPhoto: _handleAddPhoto,
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        PanelLocationSection(
                          location: _panelContent!.properties.location,
                          onTap: _handleOpenMaps,
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        PanelLinkSection(
                          url: _panelContent!.properties.url,
                          onTap: () =>
                              launchUrl(_panelContent!.properties.url!),
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        AttributeDisplay(
                          details: _panelContent!.properties.details,
                          amenities: _panelContent!.properties.amenities,
                          equipment: _panelContent!.properties.equipment,
                          onEditTap: _handleEdit
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: IconButton(
            icon: const Icon(Icons.close, color: AppColors.dark),
            onPressed: _handleClosePanel,
          ),
        ),
      ],
    );
  }
}
