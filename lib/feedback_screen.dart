import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:nyc_public_space_map/colors.dart';

class FeedbackScreen extends StatefulWidget {
  final PublicSpaceFeature? selectedFeature;
  const FeedbackScreen({this.selectedFeature, super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final String googleFormUrl =
      'https://docs.google.com/forms/u/0/d/e/1FAIpQLSdeRW4c1k16zHkkN3XO25PuRjoGxgOszSNAGV5zcKy6a4Afxw/formResponse';
  final String idField = 'entry.495981289';
  final String issueField = 'entry.823964625';

  Future<void> _submitForm(String spaceId, String inputText) async {
    setState(() {
      _isSubmitting = true;
    });

    final response = await http.post(
      Uri.parse(googleFormUrl),
      body: {
        idField: spaceId,
        issueField: inputText,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 302) {
      setState(() {
        _isSubmitted = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit. Please try again.')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final String spaceName =
        widget.selectedFeature?.properties.name ?? "this space";

    final String spaceId =
        widget.selectedFeature?.properties.space_id ?? 'app_feedback';

    String title = widget.selectedFeature != null
        ? 'Report an Issue'
        : 'Share your Feedback';

    String submittedMessage = widget.selectedFeature != null
        ? 'Thanks for reporting! We will look into it and update the record as soon as possible. 😎'
        : 'Thanks for sharing! We will use your feedback to improve the app! 😎';

    Widget prompt() {
      if (widget.selectedFeature == null) {
        return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your feedback about the app is appreciated!',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              Text(
                  'Feel free to share anything, including suggestions about the user interface, public spaces we may have missed, bugs, errors, or anything else you want to share.',
                  style: TextStyle(fontSize: 16)),
            ]);
      }
      return Text.rich(
        TextSpan(
          text:
              'Describe the issue you\'re seeing with our information about ', // Regular text
          children: [
            TextSpan(
              text: spaceName, // The space name
              style: const TextStyle(
                  fontWeight: FontWeight.bold), // Bold style for spaceName
            ),
            const TextSpan(
              text: ':', // Regular colon
            ),
          ],
        ),
        style: const TextStyle(fontSize: 16),
      );
    }

    return Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  // padding: const EdgeInsets.all(16.0),
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
                                  prompt(),
                                  const SizedBox(height: 36),
                                  TextField(
                                    controller: _controller,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(
                                                0xAA77bb3f)), // Green border when focused
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _isSubmitting
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          onPressed: () {
                                            if (_controller.text.isNotEmpty) {
                                              _submitForm(
                                                  spaceId, _controller.text);
                                            }
                                          },
                                          style: AppStyles.buttonStyle,
                                          child: const Text('Submit'),
                                        ),
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
