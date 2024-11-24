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
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      print(user.toString());
      if (user == null) {
        throw Exception('No user is logged in');
      }

      // Upload to Firebase Storage

      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('spaces_images_moderation')
          .child(widget.spaceId)  
          .child(filename);
      final uploadTask = await storageRef.putFile(_selectedImage!);
      final imageUrl = await uploadTask.ref.getDownloadURL();
      // Save to Firestore
      await FirebaseFirestore.instance.collection('images_moderation').add({
        'spaceId': widget.spaceId,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'filename': filename,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo submitted successfully!')),
      );

      Navigator.of(context).pop(); // Close the screen after submission
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
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
        title: const Text('Submit Photo'),
      ),
      body: Center(
        child: _isUploading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _selectedImage != null
                      ? Image.file(_selectedImage!)
                      : const Text('No image selected.'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera),
                        label: const Text('Take Photo'),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Choose from Gallery'),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectedImage != null ? _uploadPhoto : null,
                    child: const Text('Submit Photo'),
                  ),
                ],
              ),
      ),
    );
  }
}
