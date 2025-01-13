import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'colors.dart';
import 'user_provider.dart';

class PhotoSubmissionScreen extends StatefulWidget {
  final String spaceId;
  final VoidCallback? onSubmissionComplete;

  const PhotoSubmissionScreen({
    super.key,
    required this.spaceId,
    this.onSubmissionComplete,
  });

  @override
  _PhotoSubmissionScreenState createState() => _PhotoSubmissionScreenState();
}

class _PhotoSubmissionScreenState extends State<PhotoSubmissionScreen> {
  List<File> _selectedImages = [];
  bool _isUploading = false;

  Future<void> _pickImages(ImageSource source) async {
    final picker = ImagePicker();
    List<XFile>? pickedFiles;

    if (source == ImageSource.gallery) {
      pickedFiles = await picker.pickMultiImage();
    } else if (source == ImageSource.camera) {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        pickedFiles = [pickedFile];
      }
    }

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles!.map((file) => File(file.path)));
      });
    } else {
      // Optionally handle the case where no files were picked
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images were selected.')),
      );
    }
  }

  Future<void> _uploadPhotos() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is logged in');
      }

      for (var image in _selectedImages) {
        // Check file size
        final file = File(image.path);
        final fileSize = await file.length(); // File size in bytes
        print('File size: $fileSize bytes');
        final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('spaces_images')
            .child(widget.spaceId)
            .child(filename);
        await storageRef.putFile(image);
        print('here');

        // Save metadata to Firestore
        await FirebaseFirestore.instance.collection('images').add({
          'spaceId': widget.spaceId,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'username': userProvider.username,
          'filename': filename,
          'status': 'pending'
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos submitted successfully!')),
      );

      Navigator.of(context).pop(); // Close the screen after submission

      if (widget.onSubmissionComplete != null) {
        widget.onSubmissionComplete!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photos: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Photos'),
      ),
      body: Center(
        child: _isUploading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _selectedImages.isNotEmpty
                      ? SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        )
                      : const Text('No images selected.'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    style: AppStyles.buttonStyle,
                    label: const Text('Choose from Gallery'),
                    onPressed: () => _pickImages(ImageSource.gallery),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    style: AppStyles.buttonStyle,
                    label: const Text('Take a Photo'),
                    onPressed: () => _pickImages(ImageSource.camera),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        _selectedImages.isNotEmpty ? _uploadPhotos : null,
                    child: const Text('Submit Photos'),
                  ),
                ],
              ),
      ),
    );
  }
}
