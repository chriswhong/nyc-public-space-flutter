import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';


import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:nyc_public_space_map/colors.dart';

import './static_map_with_edit.dart';
import './attribute_checkboxes.dart';
import 'user_provider.dart';


class HeadingText extends StatelessWidget {
  final String text;

  const HeadingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16, // You can adjust this size as needed
          ),
        ),
      ),
      const SizedBox(height: 10)
    ]);
  }
}

class EditorScreen extends StatefulWidget {
  final PublicSpaceFeature? selectedFeature;
  const EditorScreen({this.selectedFeature, super.key});

  @override
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final Set<String> _selectedDetails = {};
  final Set<String> _selectedAmenities = {};
  final Set<String> _selectedEquipment = {};

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late Point _currentPoint;
  late TextEditingController _urlController;

  final Map<String, String> _typeOptions = {
    'pops': 'Privately Owned Public Space',
    'park': 'Park',
    'wpaa': 'Waterfront Public Access Area',
    'plaza': 'Street Plaza',
    'stp': 'Schoolyard to Playgrounds',
    'misc': 'Miscellaneous',
  };

  String? _selectedType;



  @override
  void initState() {
    super.initState();
    final props = widget.selectedFeature?.properties;

    _nameController = TextEditingController(text: props?.name ?? '');
    _descriptionController =
        TextEditingController(text: props?.description ?? '');
    _locationController = TextEditingController(text: props?.location ?? '');
    _selectedType = props?.type ?? 'misc'; // default fallback

    _urlController = TextEditingController(
      text: widget.selectedFeature?.properties.url?.toString() ?? '',
    );

    _currentPoint = Point(
      coordinates: Position(
        widget.selectedFeature?.geometry.coordinates.lng ?? -74.0060,
        widget.selectedFeature?.geometry.coordinates.lat ?? 40.7128,
      ),
    );

    _selectedDetails.addAll(props?.details ?? []);
    _selectedAmenities.addAll(props?.amenities ?? []);
    _selectedEquipment.addAll(props?.equipment ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _urlController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    String title = "Edit this Space";

    String submittedMessage = 'Thanks for submitting your changes! We will review them shortly.';

    return Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _isSubmitted
                          ? Center(
                              child: Text(
                                submittedMessage,
                                style: const TextStyle(fontSize: 18),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                            labelText: 'Name'),
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                                ? 'Enter a name'
                                                : null,
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        value: _selectedType,
                                        items:
                                            _typeOptions.entries.map((entry) {
                                          return DropdownMenuItem<String>(
                                            value: entry.key,
                                            child: Text(entry.value),
                                          );
                                        }).toList(),
                                        decoration: const InputDecoration(
                                            labelText: 'Type'),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedType = value!;
                                          });
                                        },
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                                ? 'Please select a type'
                                                : null,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _descriptionController,
                                        decoration: const InputDecoration(
                                            labelText: 'Description'),
                                        maxLines: 3,
                                      ),
                                      const SizedBox(height: 16),
                                      HeadingText('Location'),
                                      TextFormField(
                                        controller: _locationController,
                                        decoration: const InputDecoration(
                                            labelText: 'Location'),
                                      ),
                                      const SizedBox(height: 16),
                                      StaticMapWithEdit(
                                        initialPoint: Point(
                                          coordinates: Position(
                                            widget.selectedFeature?.geometry
                                                    .coordinates.lng ??
                                                -74.0060,
                                            widget.selectedFeature?.geometry
                                                    .coordinates.lat ??
                                                40.7128,
                                          ),
                                        ),
                                        type: _selectedType!,
                                        onLocationChanged: (Point newPoint) {
                                          setState(() {
                                            _currentPoint = newPoint;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      HeadingText('Links'),
                                      TextFormField(
                                        controller: _urlController,
                                        decoration: const InputDecoration(
                                            labelText: 'URL'),
                                        keyboardType: TextInputType.url,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty)
                                            return null; // Optional field
                                          final urlPattern =
                                              '^(https?:\\/\\/)?([\\w\\-])+\\.([a-zA-Z]{2,63})([\\/\\w\\-.~:?#[\\]@!\$&\'()*+,;=]*)?\$';
                                          final urlRegex = RegExp(urlPattern);
                                          return urlRegex.hasMatch(value.trim())
                                              ? null
                                              : 'Enter a valid URL';
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      AttributeCheckboxes(
                                        selectedDetails: _selectedDetails,
                                        selectedAmenities: _selectedAmenities,
                                        selectedEquipment: _selectedEquipment,
                                        onChanged: (category, key, isChecked) {
                                          setState(() {
                                            final set = {
                                              'details': _selectedDetails,
                                              'amenities': _selectedAmenities,
                                              'equipment': _selectedEquipment,
                                            }[category];

                                            if (set != null) {
                                              isChecked
                                                  ? set.add(key)
                                                  : set.remove(key);
                                            }
                                          });
                                        },
                                      ),
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : () async {
                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    final original = widget
                                                        .selectedFeature
                                                        ?.properties;

                                                    final urlText =
                                                        _urlController.text
                                                            .trim();
                                                    final originalUrl = original
                                                            ?.url
                                                            ?.toString() ??
                                                        '';

                                                    final updatedFields =
                                                        <String, dynamic>{};

                                                    final originalPoint = widget
                                                        .selectedFeature
                                                        ?.geometry;

                                                    if (originalPoint != null) {
                                                      final newCoords =
                                                          _currentPoint
                                                              .coordinates;
                                                      final originalCoords =
                                                          originalPoint
                                                              .coordinates;

                                                      final locationChanged =
                                                          newCoords.lat !=
                                                                  originalCoords
                                                                      .lat ||
                                                              newCoords.lng !=
                                                                  originalCoords
                                                                      .lng;

                                                      if (locationChanged) {
                                                        final geometryString =
                                                            '{"type":"Point","coordinates":[${newCoords.lng},${newCoords.lat}]}';
                                                        updatedFields[
                                                                'geometry'] =
                                                            geometryString;
                                                      }
                                                    }

                                                    void addIfChanged(
                                                        String key,
                                                        dynamic newValue,
                                                        dynamic originalValue) {
                                                      if (newValue is List &&
                                                          originalValue
                                                              is List) {
                                                        final newList =
                                                            List<String>.from(
                                                                newValue);
                                                        final originalList =
                                                            List<String>.from(
                                                                originalValue);

                                                        newList.sort();
                                                        originalList.sort();

                                                        if (newList.length !=
                                                                originalList
                                                                    .length ||
                                                            !newList
                                                                .asMap()
                                                                .entries
                                                                .every((e) =>
                                                                    e.value ==
                                                                    originalList[
                                                                        e.key])) {
                                                          updatedFields[key] =
                                                              newValue;
                                                        }
                                                      } else {
                                                        if (newValue !=
                                                            originalValue) {
                                                          updatedFields[key] =
                                                              newValue;
                                                        }
                                                      }
                                                    }

                                                    addIfChanged(
                                                        'name',
                                                        _nameController.text
                                                            .trim(),
                                                        original?.name?.trim());
                                                    addIfChanged(
                                                        'type',
                                                        _selectedType,
                                                        original?.type);
                                                    addIfChanged(
                                                        'description',
                                                        _descriptionController
                                                            .text
                                                            .trim(),
                                                        original?.description
                                                            ?.trim());

                                                    addIfChanged(
                                                        'location',
                                                        _locationController.text
                                                            .trim(),
                                                        original?.location
                                                            ?.trim());

                                                    addIfChanged(
                                                        'url',
                                                        urlText.isNotEmpty
                                                            ? urlText
                                                            : null,
                                                        originalUrl.isNotEmpty
                                                            ? originalUrl
                                                            : null);

                                                    addIfChanged(
                                                        'details',
                                                        _selectedDetails
                                                            .toList(),
                                                        original?.details ??
                                                            []);
                                                    addIfChanged(
                                                        'amenities',
                                                        _selectedAmenities
                                                            .toList(),
                                                        original?.amenities ??
                                                            []);
                                                    addIfChanged(
                                                        'equipment',
                                                        _selectedEquipment
                                                            .toList(),
                                                        original?.equipment ??
                                                            []);

                                                    if (updatedFields.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              const SnackBar(
                                                                  content: Text(
                                                                      "No changes detected.")));
                                                      return;
                                                    }

                                                    final user = FirebaseAuth
                                                        .instance.currentUser;


                                                    final submission = {
                                                      'spaceId': widget
                                                              .selectedFeature
                                                              ?.properties
                                                              .firestoreId ??
                                                          'unknown',
                                                      'status': 'pending',
                                                      'timestamp': FieldValue
                                                          .serverTimestamp(),
                                                      'userId': user?.uid ??
                                                          'anonymous',
                                                      'userName': userProvider.username,
                                                      'proposedData':
                                                          updatedFields,
                                                    };

                                                    print(
                                                        "📤 Writing submission to Firestore:");
                                                    submission.forEach(
                                                        (key, value) => print(
                                                            '  $key: $value'));

                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'public-spaces-edits')
                                                        .add(submission);

                                                    setState(() {
                                                      _isSubmitted = true;
                                                    });
                                                  }
                                                },
                                          child: _isSubmitting
                                              ? const CircularProgressIndicator()
                                              : const Text('Submit'),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
