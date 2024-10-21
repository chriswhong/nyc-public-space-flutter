import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

class ReportIssueDrawer extends StatefulWidget {
  const ReportIssueDrawer({super.key});

  @override
  _ReportIssueDrawerState createState() => _ReportIssueDrawerState();
}

class _ReportIssueDrawerState extends State<ReportIssueDrawer> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final String googleFormUrl =
      'https://docs.google.com/forms/u/0/d/e/1FAIpQLSdeRW4c1k16zHkkN3XO25PuRjoGxgOszSNAGV5zcKy6a4Afxw/formResponse';
  final String idField = 'entry.495981289';
  final String issueField = 'entry.823964625';

  Future<void> _submitForm(String inputText) async {
    setState(() {
      _isSubmitting = true;
    });

    final response = await http.post(
      Uri.parse(googleFormUrl),
      body: {
        idField: 'foo',
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

    return Drawer(
      width: screenWidth, // Set full-width for the drawer
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeader(context, 'Report an Issue'),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _isSubmitted
                          ? const Center(
                              child: Text(
                                'Thank you for your submission!',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Please describe the issue:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _controller,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter your message',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _isSubmitting
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        onPressed: () {
                                          if (_controller.text.isNotEmpty) {
                                            _submitForm(_controller.text);
                                          }
                                        },
                                        child: const Text('Submit'),
                                      ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.times),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
