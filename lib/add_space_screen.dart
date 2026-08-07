import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'colors.dart';
import 'static_map_with_edit.dart';
import 'user_provider.dart';

class AddSpaceScreen extends StatefulWidget {
  final Point? initialPoint;
  const AddSpaceScreen({super.key, this.initialPoint});

  @override
  State<AddSpaceScreen> createState() => _AddSpaceScreenState();
}

class _AddSpaceScreenState extends State<AddSpaceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _urlController = TextEditingController();

  String _selectedType = 'park';

  late Point _currentPoint;

  static const Map<String, String> _typeOptions = {
    'pops': 'Privately Owned Public Space',
    'park': 'Park',
    'wpaa': 'Waterfront Public Access Area',
    'plaza': 'Street Plaza',
    'stp': 'Schoolyard to Playgrounds',
    'misc': 'Miscellaneous',
  };

  @override
  void initState() {
    super.initState();
    _currentPoint = widget.initialPoint ??
        Point(coordinates: Position(-74.0060, 40.7128));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() => _isSubmitting = true);

    try {
      final geometryString =
          '{"type":"Point","coordinates":[${_currentPoint.coordinates.lng},${_currentPoint.coordinates.lat}]}';

      await FirebaseFirestore.instance
          .collection('public-spaces-submissions')
          .add({
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'geometry': geometryString,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'url': _urlController.text.trim(),
        'userId': user.uid,
        'username': userProvider.username,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        setState(() {
          _isSubmitted = true;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Add a Space')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _isSubmitted
                    ? const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64, color: Colors.green),
                            SizedBox(height: 16),
                            Text(
                              'Thanks for submitting!',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Our team will review your submission and add it to the map.',
                              style: TextStyle(fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            const Text(
                              'Know a public space that\'s missing from the map? Submit it here and we\'ll review it.',
                              style: TextStyle(fontSize: 14, color: AppColors.gray),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              decoration:
                                  const InputDecoration(labelText: 'Name *'),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Enter a name'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedType,
                              items: _typeOptions.entries
                                  .map((e) => DropdownMenuItem(
                                      value: e.key, child: Text(e.value)))
                                  .toList(),
                              decoration:
                                  const InputDecoration(labelText: 'Type *'),
                              onChanged: (v) =>
                                  setState(() => _selectedType = v!),
                              validator: (v) =>
                                  (v == null || v.isEmpty)
                                      ? 'Select a type'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                  labelText: 'Description (optional)'),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                  labelText: 'Address / Location (optional)'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _urlController,
                              decoration: const InputDecoration(
                                  labelText: 'Website URL (optional)'),
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Location *',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Drag the pin to set the exact location.',
                              style:
                                  TextStyle(fontSize: 12, color: AppColors.gray),
                            ),
                            const SizedBox(height: 8),
                            StaticMapWithEdit(
                              initialPoint: _currentPoint,
                              type: _selectedType,
                              onLocationChanged: (p) =>
                                  setState(() => _currentPoint = p),
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.dark,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Submit for Review'),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
