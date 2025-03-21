import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:nyc_public_space_map/colors.dart';

import './draggable_mapbox_marker.dart';
import './static_map_with_edit.dart';

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

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late List<TextEditingController> _urlControllers;

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

    _urlControllers = [];

    final existingUrls = props?.urls ??
        (props?.url != null && props!.url!.toString().isNotEmpty
            ? [props.url!]
            : []);

    for (var url in existingUrls) {
      _urlControllers.add(TextEditingController(text: url.toString()));
    }

// If no existing URLs, add one empty field by default
    if (_urlControllers.isEmpty) {
      _urlControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();

    for (final controller in _urlControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // final String googleFormUrl =
  //     'https://docs.google.com/forms/u/0/d/e/1FAIpQLSdeRW4c1k16zHkkN3XO25PuRjoGxgOszSNAGV5zcKy6a4Afxw/formResponse';
  // final String idField = 'entry.495981289';
  // final String issueField = 'entry.823964625';

  // Future<void> _submitForm(String spaceId, String inputText) async {
  //   setState(() {
  //     _isSubmitting = true;
  //   });

  //   final response = await http.post(
  //     Uri.parse(googleFormUrl),
  //     body: {
  //       idField: spaceId,
  //       issueField: inputText,
  //     },
  //   );

  //   if (response.statusCode == 200 || response.statusCode == 302) {
  //     setState(() {
  //       _isSubmitted = true;
  //     });
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to submit. Please try again.')),
  //     );
  //   }

  //   setState(() {
  //     _isSubmitting = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final String spaceName =
        widget.selectedFeature?.properties.name ?? "this space";

    final String spaceId =
        widget.selectedFeature?.properties.space_id ?? 'app_feedback';

    String title = "Edit this Space";

    String submittedMessage = widget.selectedFeature != null
        ? 'Thanks for reporting! We will look into it and update the record as soon as possible. 😎'
        : 'Thanks for sharing! We will use your feedback to improve the app! 😎';

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
                                          print(
                                              "New LatLng: ${newPoint.coordinates.lat}, ${newPoint.coordinates.lng}");
                                          // Save to state here if you need to pass it on form submission
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      HeadingText('Links'),
                                      Column(
                                        children: [
                                          const SizedBox(height: 8),
                                          ..._urlControllers
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final index = entry.key;
                                            final controller = entry.value;
                                            return Column(children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller: controller,
                                                      keyboardType:
                                                          TextInputType.url,
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value
                                                                .trim()
                                                                .isEmpty) {
                                                          return null; // Field is optional
                                                        }

                                                        final urlPattern =
                                                            '^(https?:\\/\\/)?([\\w\\-])+\\.([a-zA-Z]{2,63})([\\/\\w\\-.~:?#[\\]@!\$&\'()*+,;=]*)?\$';
                                                        final urlRegex =
                                                            RegExp(urlPattern);

                                                        bool isValid =
                                                            urlRegex.hasMatch(
                                                                value.trim());
                                                        return isValid
                                                            ? null
                                                            : 'Enter a valid URL';
                                                      },
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete_outline),
                                                    onPressed: () {
                                                      setState(() {
                                                        _urlControllers
                                                            .removeAt(index);
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8)
                                            ]);
                                          }),
                                          TextButton.icon(
                                            icon: const Icon(Icons.add),
                                            label: const Text('Add Link'),
                                            onPressed: () {
                                              setState(() {
                                                _urlControllers.add(
                                                    TextEditingController());
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : () {
                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    // TODO: Submit form logic here
                                                    print("Submitting:");
                                                    print(
                                                        "Name: ${_nameController.text}");
                                                    print(
                                                        "Type: $_selectedType");
                                                    print(
                                                        "Description: ${_descriptionController.text}");
                                                    print(
                                                        "Location: ${_locationController.text}");

                                                    final urls = _urlControllers
                                                        .map((c) =>
                                                            c.text.trim())
                                                        .where((text) =>
                                                            text.isNotEmpty)
                                                        .toList();

                                                    print(
                                                        "Submitted URLs: $urls");

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
    // return Drawer(
    //   width: screenWidth, // Set full-width for the drawer
    //   child: SafeArea(
    //     child:
    //   ),
    // );
  }
}
