import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhotoSubmissionScreen extends StatefulWidget {
  final String spaceId;

  const PhotoSubmissionScreen({
    super.key,
    required this.spaceId,
  });

  @override
  _PhotoSubmissionScreenState createState() => _PhotoSubmissionScreenState();
}

class _PhotoSubmissionScreenState extends State<PhotoSubmissionScreen> {
  List<File> _selectedImages = [];
  bool _isUploading = false;

  Future<void> _pickImages(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _uploadPhotos() async {
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
        final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('spaces_images')
            .child(widget.spaceId)
            .child(filename);
        final uploadTask = await storageRef.putFile(image);
        final imageUrl = await uploadTask.ref.getDownloadURL();

        // Save metadata to Firestore
        await FirebaseFirestore.instance.collection('images').add({
          'spaceId': widget.spaceId,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'filename': filename,
          'approved': false,
          'imageUrl': imageUrl,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos submitted successfully!')),
      );

      Navigator.of(context).pop(); // Close the screen after submission
    } catch (e) {
      print(e);
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
                    label: const Text('Choose Images'),
                    onPressed: () => _pickImages(ImageSource.gallery),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectedImages.isNotEmpty ? _uploadPhotos : null,
                    child: const Text('Submit Photos'),
                  ),
                ],
              ),
      ),
    );
  }
}