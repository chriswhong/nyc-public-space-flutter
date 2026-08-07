import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:provider/provider.dart';

import '../public_space_properties.dart';
import '../submit_image.dart';
import '../editor_screen.dart';
import '../sign_in_screen.dart';
import '../colors.dart';
import '../favorites_provider.dart';
import '../visited_provider.dart';
import '../user_provider.dart';
import 'panel_header.dart';
import 'panel_image_gallery.dart';
import 'panel_action_buttons.dart';
import 'panel_location_section.dart';
import 'panel_link_section.dart';
import '../feedback_screen.dart';
import 'panel_activity_section.dart';
import 'temporarily_closed_banner.dart';
import 'amenity_survey_section.dart';

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

  // Amenity survey data
  Map<String, Map<String, int>> _amenitySurvey = {};
  Map<String, bool> _userVotes = {};

  // Report-closed/open state
  bool _reportClosedSubmitted = false;
  bool _reportOpenSubmitted = false;

  @override
  void initState() {
    super.initState();
    _panelContent = widget.selectedFeature;
    fetchImages();
    fetchFavoriteCount();
    fetchSpaceDetails();
    fetchUserVotes();
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
        _amenitySurvey = {};
        _userVotes = {};
        _reportClosedSubmitted = false;
        _reportOpenSubmitted = false;
      });
      fetchImages();
      fetchFavoriteCount();
      fetchSpaceDetails();
      fetchUserVotes();
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
      // ignore
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

        // Parse amenity survey data
        final rawSurvey = data['amenity_survey'] as Map<String, dynamic>?;
        if (rawSurvey != null) {
          _amenitySurvey = rawSurvey.map((k, v) =>
              MapEntry(k, Map<String, int>.from(v as Map)));
        }
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> fetchUserVotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final id = widget.selectedFeature?.properties.firestoreId;
    if (id == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('amenity-votes')
          .doc(id)
          .get();
      if (!mounted) return;
      setState(() {
        _userVotes = snap.exists
            ? Map<String, bool>.from(snap.data()!)
            : {};
      });
    } catch (e) {
      // ignore
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

  Future<void> _handleReportClosed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SignInScreen()));
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentDetails = _fetchedDetails.isNotEmpty
        ? _fetchedDetails
        : _panelContent!.properties.details;

    if (currentDetails.contains('temporarily_closed')) return;

    try {
      await FirebaseFirestore.instance.collection('public-spaces-edits').add({
        'spaceId': _panelContent!.properties.firestoreId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userName': userProvider.username,
        'proposedData': {
          'details': [...currentDetails, 'temporarily_closed'],
        },
      });
      if (mounted) {
        setState(() => _reportClosedSubmitted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thanks! Our team will review this report.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  Future<void> _handleReportOpen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SignInScreen()));
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentDetails = _fetchedDetails.isNotEmpty
        ? _fetchedDetails
        : _panelContent!.properties.details;

    try {
      await FirebaseFirestore.instance.collection('public-spaces-edits').add({
        'spaceId': _panelContent!.properties.firestoreId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userName': userProvider.username,
        'proposedData': {
          'details': currentDetails
              .where((d) => d != 'temporarily_closed')
              .toList(),
        },
      });
      if (mounted) {
        setState(() => _reportOpenSubmitted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thanks! Our team will review this report.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_panelContent == null) return const SizedBox.shrink();

    final effectiveDetails = _fetchedDetails.isNotEmpty
        ? _fetchedDetails
        : _panelContent!.properties.details;
    final isClosed = effectiveDetails.contains('temporarily_closed');

    final effectiveDescription =
        _fetchedDescription ?? _panelContent!.properties.description;
    final effectiveLocation =
        _fetchedLocation ?? _panelContent!.properties.location;
    final effectiveUrl = _fetchedUrl ?? _panelContent!.properties.url;

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
                // Header row: name, type pill, favorites
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
                // "Been here" visited toggle
                Consumer<VisitedProvider>(
                  builder: (context, visitedProvider, _) {
                    final isVisited = visitedProvider
                        .isVisited(_panelContent!.properties.firestoreId);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignInScreen()),
                            );
                          } else {
                            visitedProvider.toggle(_panelContent!);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isVisited
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                size: 16,
                                color:
                                    isVisited ? Colors.green : Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isVisited ? 'Been here' : 'Been here?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isVisited
                                      ? Colors.green
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(color: AppColors.gray, thickness: 0.5),
                Expanded(
                  child: SingleChildScrollView(
                    physics: widget.isExpanded
                        ? null
                        : const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Temporarily closed banner
                        if (isClosed) const TemporarilyClosedBanner(),

                        // 2. Description
                        if (effectiveDescription?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(effectiveDescription!),
                          ),
                        const Divider(color: AppColors.gray, thickness: 0.5),

                        // 3. Image gallery
                        PanelImageGallery(
                          imageList: imageList,
                          isLoading: _isLoading,
                          onAddPhoto: _handleAddPhoto,
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),

                        // 4. Action buttons
                        PanelActionButtons(
                          onOpenMaps: _handleOpenMaps,
                          onEdit: _handleEdit,
                          onSubmitPhoto: _handleAddPhoto,
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),

                        // 5. Location + link
                        PanelLocationSection(
                          location: effectiveLocation,
                          onTap: _handleOpenMaps,
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),
                        PanelLinkSection(
                          url: effectiveUrl,
                          onTap: () => launchUrl(effectiveUrl!),
                        ),
                        const Divider(color: AppColors.gray, thickness: 0.5),

                        // 6. Amenity micro-survey
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: AmenitySurveySection(
                            spaceId: _panelContent!.properties.firestoreId,
                            amenitySurvey: _amenitySurvey,
                            userVotes: _userVotes,
                            onSignInRequired: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignInScreen()),
                            ),
                          ),
                        ),


                        // 8. Report closed / open again
                        if (!isClosed && !_reportClosedSubmitted)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextButton.icon(
                              icon: const Icon(Icons.report_outlined, size: 14),
                              label: const Text(
                                'Report as temporarily closed',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.gray,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _handleReportClosed,
                            ),
                          ),
                        if (isClosed && !_reportOpenSubmitted)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 14),
                              label: const Text(
                                'Report as open again',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.gray,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _handleReportOpen,
                            ),
                          ),
                        const Divider(color: AppColors.gray, thickness: 0.5),

                        // 9. Recent contributions
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

                        // 10. Feedback button
                        const SizedBox(height: 10),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(36),
                            ),
                            minimumSize: const Size(0, 10),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Share feedback about this space',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
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
