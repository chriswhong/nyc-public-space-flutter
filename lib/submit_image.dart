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
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) pickedFiles = [pickedFile];
    }

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles!.map((f) => File(f.path)));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images were selected.')),
      );
    }
  }

  Future<void> _uploadPhotos() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (_selectedImages.isEmpty) return;
    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user is logged in');

      for (final image in _selectedImages) {
        final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('spaces_images')
            .child(widget.spaceId)
            .child(filename);
        await storageRef.putFile(image);
        await FirebaseFirestore.instance.collection('images').add({
          'spaceId': widget.spaceId,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'username': userProvider.username,
          'filename': filename,
          'status': 'pending',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos submitted successfully!')),
      );
      Navigator.of(context).pop();
      widget.onSubmissionComplete?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photos: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _selectedImages.length;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Submit Photos')),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (count > 0) ...[
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: count,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _PickerRow(
                    icon: Icons.photo_library_outlined,
                    label: 'Choose from Gallery',
                    onTap: () => _pickImages(ImageSource.gallery),
                  ),
                  const SizedBox(height: 12),
                  _PickerRow(
                    icon: Icons.camera_alt_outlined,
                    label: 'Take a Photo',
                    onTap: () => _pickImages(ImageSource.camera),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: count > 0 ? _uploadPhotos : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentDark,
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      count > 0 ? 'Submit $count photo${count == 1 ? '' : 's'}' : 'Submit Photos',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.accentDark),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}
