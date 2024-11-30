import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './public_space_properties.dart';
import './colors.dart';
import './submit_image.dart';
import './feedback_screen.dart';
import './sign_in_screen.dart';
import './image_viewer.dart';

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

  const PanelHandler(
      {super.key,
      required this.selectedFeature,
      this.onClosePanel,
      this.onPanelContentUpdated});

  @override
  _PanelHandlerState createState() => _PanelHandlerState();
}

class _PanelHandlerState extends State<PanelHandler> {
  late PublicSpaceFeature? _panelContent;
  List<Map<String, dynamic>> imageList = [];
  bool _isLoading = true; // Initially loading

  @override
  void initState() {
    super.initState();
    // Initialize with an empty feature or the passed selectedFeature
    _panelContent = widget.selectedFeature;
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

      print(querySnapshot.docs.length);

      List<Map<String, dynamic>> imageListUpdate = [];
      for (var doc in querySnapshot.docs) {
        String filename = doc['filename'];
        String spaceId = doc['spaceId'];
        String status = doc['status'];
        String username = doc['username'];
        Timestamp timestamp = doc['timestamp'];
        
        String thumbnailUrl = await getThumbnailUrl(filename, spaceId);
        String mediumUrl = await getMediumUrl(filename, spaceId);

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
        _isLoading = false; // Loading complete
      });
    } catch (e) {
      print('Error fetching images: $e');
      setState(() {
        _isLoading = false; // Loading complete even if there is an error
      });
    }
  }

  Future<String> getThumbnailUrl(String filename, String spaceId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('spaces_images/$spaceId/thumbnail/$filename');
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting thumbnail URL: $e');
      return '';
    }
  }

  Future<String> getMediumUrl(String filename, String spaceId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('spaces_images/$spaceId/medium/$filename');
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting medium URL: $e');
      return '';
    }
  }

  // Update the panel when the selectedFeature changes
  @override
  void didUpdateWidget(PanelHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFeature != oldWidget.selectedFeature &&
        widget.selectedFeature != null) {
      setState(() {
        imageList = [];
        _panelContent = widget.selectedFeature;
        _isLoading = true; // Reset loading state
      });
      fetchImages();
    }
  }

  void _handleClosePanel() {
    if (widget.onClosePanel != null) {
      widget.onClosePanel!();
    }
    setState(() {
      _isLoading = true; // Reset loading state
      imageList = []; // Clear image list
    });
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
            title: const Text('Open in Maps'),
            content: const Text('Which app would you like to use?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Apple Maps'),
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
                child: const Text('Google Maps'),
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
    return const Divider(
      color: AppColors.gray, // Color of the line
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
        typeColor = AppColors.popsColor;
        break;
      case 'park':
        typeLabel = 'Park';
        typeColor = AppColors.parkColor;
        break;
      case 'wpaa':
        typeLabel = 'Waterfront Public Access Area';
        typeColor = AppColors.wpaaColor;
        break;
      case 'plaza':
        typeLabel = 'Street Plaza';
        typeColor = AppColors.plazaColor;
        break;
      case 'stp':
        typeLabel = 'Schoolyards to Playgrounds';
        typeColor = AppColors.stpColor;
        break;
      default:
        typeLabel = 'Miscellaneous';
        typeColor = AppColors.miscColor;
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
          bottom: 10, // Add bottom constraint for scrollability

          child: Container(
            padding: const EdgeInsets.all(8.0),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: [
                      if (_isLoading)
                        const SizedBox(
                          height: 160, // Spinner height
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (imageList.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: imageList.map((imageData) {
                              final String status = imageData['status'];
                              final String thumbnailUrl =
                                  imageData['thumbnailUrl'];

                              return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ImageViewer(
                                          imageList: imageList,
                                          initialIndex:
                                              imageList.indexOf(imageData),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            thumbnailUrl,
                                            height: 160,
                                            width: 200,
                                            fit: BoxFit.cover,
                                          ),
                                          if (status == 'pending')
                                            Positioned.fill(
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                    sigmaX: 10.0, sigmaY: 10.0),
                                                child: Container(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  child: const Center(
                                                    child: Text(
                                                      'Pending Approval',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ));
                            }).toList(),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey, // Border color
                              width: 0.5, // Border width
                            ),
                            borderRadius:
                                BorderRadius.circular(16.0), // Rounded corners
                          ),
                          padding: const EdgeInsets.all(16.0),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 10.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.photo_album,
                                size: 40,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'No photos available for this space.',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                icon: const Icon(FontAwesomeIcons.camera),
                                style: AppStyles.buttonStyle,
                                label: const Text('Add the first photo'),
                                onPressed: () {
                                  final user =
                                      FirebaseAuth.instance.currentUser;

                                  if (user != null) {
                                    // If the user is signed in, navigate to the PhotoSubmissionScreen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PhotoSubmissionScreen(
                                          spaceId: _panelContent!
                                              .properties.firestoreId,
                                        ),
                                      ),
                                    );
                                  } else {
                                    // If the user is not signed in, navigate to the SignInScreen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignInScreen(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
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
                      Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Add padding around the row
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceEvenly, // Evenly space the buttons
                          children: [
                            // First button for "Get Directions"
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .grey[300], // Light gray background
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
                                        (_panelContent!
                                                .geometry.coordinates.lat)
                                            .toDouble(),
                                        (_panelContent!
                                                .geometry.coordinates.lng)
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
                                  style: TextStyle(
                                      fontSize: 12), // Small text label
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .grey[300], // Light gray background
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FeedbackScreen(
                                              selectedFeature:
                                                  widget.selectedFeature),
                                        ),
                                      );
                                    },
                                    tooltip: 'Report an Issue',
                                  ),
                                ),
                                const SizedBox(
                                    height: 4), // Space between icon and text
                                const Text(
                                  'Report a Data Issue',
                                  style: TextStyle(
                                      fontSize: 12), // Small text label
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .grey[300], // Light gray background
                                    shape: BoxShape.circle, // Circular shape
                                  ),
                                  child: IconButton(
                                    icon: FaIcon(
                                      FontAwesomeIcons
                                          .camera, // Navigation icon
                                      size: 20, // Icon size
                                      color: Colors.grey[800], // Dark gray icon
                                    ),
                                    onPressed: () async {
                                      final user =
                                          FirebaseAuth.instance.currentUser;

                                      if (user != null) {
                                        // If the user is signed in, navigate to the PhotoSubmissionScreen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PhotoSubmissionScreen(
                                              spaceId: _panelContent!
                                                  .properties.firestoreId,
                                              onSubmissionComplete: () {
                                                fetchImages(); // Callback to refresh the images
                                              }, // Replace with the space ID
                                            ),
                                          ),
                                        );
                                      } else {
                                        // If the user is not signed in, navigate to the SignInScreen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SignInScreen(), // Replace with your sign-in screen widget
                                          ),
                                        );
                                      }
                                    },
                                    tooltip: 'Report an Issue',
                                  ),
                                ),
                                const SizedBox(
                                    height: 4), // Space between icon and text
                                const Text(
                                  'Submit a Photo',
                                  style: TextStyle(
                                      fontSize: 12), // Small text label
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
                              _panelContent!
                                      .properties.description?.isNotEmpty ==
                                  true
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(_panelContent!.properties.description!),
                                _lightDivider(), // Add the additional widget here
                              ],
                            )
                          : const SizedBox.shrink(),
                      _panelContent != null &&
                              _panelContent!.properties.location != null &&
                              _panelContent!.properties.location?.isNotEmpty ==
                                  true
                          ? Column(
                              children: [
                                const SizedBox(height: 4),
                                ListTile(
                                  leading: const FaIcon(
                                      FontAwesomeIcons.mapMarkerAlt,
                                      size: 18),

                                  title: Text(
                                      _panelContent!.properties.location ??
                                          'Address not available',
                                      style: const TextStyle(fontSize: 14)),
                                  visualDensity: const VisualDensity(
                                      vertical: -4), // Reduce vertical space
                                ),
                                _lightDivider(),
                              ],
                            )
                          : const SizedBox.shrink(),
                      _panelContent != null &&
                              _panelContent!.properties.url != null
                          ? Column(
                              children: [
                                const SizedBox(height: 4),
                                ListTile(
                                  leading: const FaIcon(FontAwesomeIcons.link,
                                      size: 18),

                                  title: Text(
                                      extractDomainFromUri(
                                          _panelContent!.properties.url),
                                      style: const TextStyle(fontSize: 14)),
                                  visualDensity: const VisualDensity(
                                      vertical: -4), // Reduce vertical space

                                  onTap: () {
                                    _launchURL(_panelContent!.properties.url);
                                  },
                                ),
                                _lightDivider(),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ]),
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
            icon: const Icon(Icons.close, color: AppColors.dark),
            onPressed: _handleClosePanel, // Call the close function when tapped
          ),
        ),
      ],
    );
  }
}
