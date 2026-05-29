import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

import 'package:provider/provider.dart';

import '../public_space_properties.dart';
import '../submit_image.dart';
import '../editor_screen.dart';
import '../sign_in_screen.dart';
import '../attribute_display.dart';
import '../colors.dart';
import '../favorites_provider.dart';
import 'panel_header.dart';
import 'panel_image_gallery.dart';
import 'panel_action_buttons.dart';
import 'panel_location_section.dart';
import 'panel_link_section.dart';
import '../feedback_screen.dart';
import 'panel_activity_section.dart';

class PanelHandler extends StatefulWidget {
  final PublicSpaceFeature? selectedFeature;
  final VoidCallback? onClosePanel;
  final bool isExpanded;

  const PanelHandler({
    super.key,
    required this.selectedFeature,
    this.onClosePanel,
    this.isExpanded = false,
  });

  @override
  State<PanelHandler> createState() => _PanelHandlerState();
}

class _PanelHandlerState extends State<PanelHandler> {
  late PublicSpaceFeature? _panelContent;
  List<Map<String, dynamic>> imageList = [];
  bool _isLoading = true;
  int _favoriteCount = 0;

  // Fields fetched from Firestore (not in slim GeoJSON)
  String? _fetchedDescription;
  String? _fetchedLocation;
  Uri? _fetchedUrl;
  List<String> _fetchedDetails = [];
  List<String> _fetchedAmenities = [];
  List<String> _fetchedEquipment = [];

  @override
  void initState() {
    super.initState();
    _panelContent = widget.selectedFeature;
    fetchImages();
    fetchFavoriteCount();
    fetchSpaceDetails();
  }

  @override
  void didUpdateWidget(covariant PanelHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFeature != oldWidget.selectedFeature) {
      setState(() {
        _panelContent = widget.selectedFeature;
        _isLoading = true;
        imageList = [];
        _favoriteCount = 0;
        _fetchedDescription = null;
        _fetchedLocation = null;
        _fetchedUrl = null;
        _fetchedDetails = [];
        _fetchedAmenities = [];
        _fetchedEquipment = [];
      });
      fetchImages();
      fetchFavoriteCount();
      fetchSpaceDetails();
    }
  }

  Future<void> fetchImages() async {
    if (widget.selectedFeature?.properties.firestoreId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {

      final querySnapshot = await FirebaseFirestore.instance
          .collection('images')
          .where('spaceId',
              isEqualTo: widget.selectedFeature!.properties.firestoreId)
          .where('status', isEqualTo: 'approved')
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
          'timestamp': timestamp,
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

  Future<void> fetchFavoriteCount() async {
    final id = widget.selectedFeature?.properties.firestoreId;
    if (id == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('favorites')
          .where('firestoreId', isEqualTo: id)
          .count()
          .get();
      if (mounted) {
        setState(() {
          _favoriteCount = snapshot.count ?? 0;
        });
      }
    } catch (e) {
      print('fetchFavoriteCount error: $e');
    }
  }

  Future<void> fetchSpaceDetails() async {
    final id = widget.selectedFeature?.properties.firestoreId;
    if (id == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('public-spaces-main')
          .doc(id)
          .get();
      if (!mounted || !doc.exists) return;
      final data = doc.data()!;
      setState(() {
        _fetchedDescription = data['description'] as String?;
        _fetchedLocation = data['location'] as String?;
        final rawUrl = data['url'] as String?;
        _fetchedUrl = (rawUrl != null && rawUrl.isNotEmpty)
            ? Uri.tryParse(rawUrl)
            : null;
        _fetchedDetails = _toStringList(data['details']);
        _fetchedAmenities = _toStringList(data['amenities']);
        _fetchedEquipment = _toStringList(data['equipment']);
      });
    } catch (e) {
      print('fetchSpaceDetails error: $e');
    }
  }

  List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    return [];
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
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favProvider, _) {
                      final isFav = favProvider
                          .isFavorite(_panelContent!.properties.firestoreId);
                      return PanelHeader(
                        name: _panelContent!.properties.name ?? '',
                        type: _panelContent!.properties.type,
                        isFavorite: isFav,
                        favoriteCount: _favoriteCount,
                        onFavoriteTap: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignInScreen()),
                            );
                          } else {
                            favProvider.toggle(_panelContent!);
                          }
                        },
                      );
                    },
                  ),
                ),
                const Divider(color: AppColors.gray, thickness: 0.5),
                Expanded(
                  child: SingleChildScrollView(
                    physics: widget.isExpanded
                        ? null
                        : const NeverScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        if ((_fetchedDescription ?? _panelContent!.properties.description)?.isNotEmpty ==
                            true)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(_fetchedDescription ?? _panelContent!.properties.description!),
                          ),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        PanelImageGallery(
                          imageList: imageList,
                          isLoading: _isLoading,
                          onAddPhoto: _handleAddPhoto,
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        PanelActionButtons(
                          onOpenMaps: _handleOpenMaps,
                          onEdit: _handleEdit,
                          onSubmitPhoto: _handleAddPhoto,
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        PanelLocationSection(
                          location: _fetchedLocation ?? _panelContent!.properties.location,
                          onTap: _handleOpenMaps,
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        PanelLinkSection(
                          url: _fetchedUrl ?? _panelContent!.properties.url,
                          onTap: () =>
                              launchUrl((_fetchedUrl ?? _panelContent!.properties.url)!),
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        AttributeDisplay(
                            details: _fetchedDetails.isNotEmpty ? _fetchedDetails : _panelContent!.properties.details,
                            amenities: _fetchedAmenities.isNotEmpty ? _fetchedAmenities : _panelContent!.properties.amenities,
                            equipment: _fetchedEquipment.isNotEmpty ? _fetchedEquipment : _panelContent!.properties.equipment,
                            onEditTap: _handleEdit),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recent Contributions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              PanelActivitySection(
                                spaceId:
                                    _panelContent!.properties.firestoreId,
                                spaceName:
                                    _panelContent!.properties.name ?? '',
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FeedbackScreen(
                                    selectedFeature: _panelContent),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            backgroundColor: Colors.grey[300],
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(36),
                            ),
                            minimumSize:
                                Size(0, 10), // Ensures the height is small
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Share feedback about this space',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        Positioned(
          right: 4,
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
