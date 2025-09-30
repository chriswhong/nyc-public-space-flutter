import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;


class ImageViewer extends StatefulWidget {
  final List<dynamic> imageList;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.imageList,
    required this.initialIndex,
  });

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Initialize PageController with the initial index
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

    String formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timeago.format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return timeago.format(timestamp);
    }
    return 'Unknown time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageList.length,
        itemBuilder: (context, index) {
          final mediumUrl = widget.imageList[index]['mediumUrl'];
          final username = widget.imageList[index]['username']; // Assuming username is available
          final timestamp = widget.imageList[index]['timestamp']; // Assuming timestamp is available

          return Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  maxScale: 5.0, // Maximum zoom scale
                  minScale: 1.0, // Minimum zoom scale
                  constrained: true, // Keep the image constrained initially
                  child: Image.network(
                    mediumUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                bottom: 50,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.user,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          username ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatTimestamp(timestamp),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}