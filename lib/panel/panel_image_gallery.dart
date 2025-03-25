import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../image_viewer.dart';
import '../colors.dart';

class PanelImageGallery extends StatelessWidget {
  final List<Map<String, dynamic>> imageList;
  final bool isLoading;
  final VoidCallback onAddPhoto;

  const PanelImageGallery({
    required this.imageList,
    required this.isLoading,
    required this.onAddPhoto,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (imageList.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 0.5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_album, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              'No photos available for this space.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(FontAwesomeIcons.camera),
              label: const Text('Add the first photo'),
              style: AppStyles.buttonStyle,
              onPressed: onAddPhoto,
            ),
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: imageList.map((imageData) {
            final String status = imageData['status'];
            final String thumbnailUrl = imageData['thumbnailUrl'];

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageViewer(
                    imageList: imageList,
                    initialIndex: imageList.indexOf(imageData),
                  ),
                ),
              ),
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
                            filter:
                                ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              color: Colors.black.withOpacity(0.2),
                              child: const Center(
                                child: Text(
                                  'Pending Approval',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
  }
}
