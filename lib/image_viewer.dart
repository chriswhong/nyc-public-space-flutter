import 'package:flutter/material.dart';

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
          return Center(
            child: InteractiveViewer(
              maxScale: 5.0, // Maximum zoom scale
              minScale: 1.0, // Minimum zoom scale
              constrained: true, // Keep the image constrained initially
              child: Image.network(
                widget.imageList[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}